defmodule IntegrationTest do
  @moduledoc """
  Integration tests for Harjus.
  """

  use ExUnit.Case, async: false
  import Mox

  alias MarketData.Types.Symbol
  require Decimal

  # use global Mox mode
  setup :set_mox_from_context
  setup :verify_on_exit!

  setup do
    # use real balance in these tests
    old_pm_balance = swap_mock_and_get_old(:pm_balance, Balance)
    old_trade_balance = swap_mock_and_get_old(:balance, Balance)

    # after tests, restore the mocks
    on_exit(fn ->
      swap_mock_and_get_old(:pm_balance, old_pm_balance)
      swap_mock_and_get_old(:balance, old_trade_balance)
    end)
  end

  @tag :integration
  test "opportunity gets captured" do
    fee = Decimal.from_float(0.001)

    # Mock Binance modules
    PriceStreamer.Exchange.TestMock
    |> expect(:new, fn _symbols ->
      :ok
    end)

    MarketData.Exchange.TestMock
    |> expect(:get_symbols, fn ->
      [
        %Symbol{
          symbol: "BTCUSDT",
          baseAsset: "BTC",
          quoteAsset: "USDT",
          baseAssetPrecision: 8,
          quoteAssetPrecision: 2,
          baseAssetIncrement: Decimal.from_float(0.000001),
          quoteAssetIncrement: Decimal.from_float(0.01)
        },
        %Symbol{
          symbol: "ETHBTC",
          baseAsset: "ETH",
          quoteAsset: "BTC",
          baseAssetPrecision: 8,
          quoteAssetPrecision: 2,
          baseAssetIncrement: Decimal.from_float(0.000001),
          quoteAssetIncrement: Decimal.from_float(0.01)
        },
        %Symbol{
          symbol: "ETHUSDT",
          baseAsset: "ETH",
          quoteAsset: "USDT",
          baseAssetPrecision: 8,
          quoteAssetPrecision: 2,
          baseAssetIncrement: Decimal.from_float(0.000001),
          quoteAssetIncrement: Decimal.from_float(0.01)
        }
      ]
    end)
    |> expect(:get_symbol_prices, fn ->
      %{
        "BTCUSDT" => Decimal.from_float(10_000.0),
        "ETHBTC" => Decimal.from_float(0.1),
        "ETHUSDT" => Decimal.from_float(1_000.0)
      }
    end)

    Trader.TradeClient.Exchange.TestMock
    |> expect(:new, fn ->
      :does_not_matter
    end)

    # 2 trades 1:1
    |> expect(:market_order, 2, fn trading_symbol, quantity ->
      %Types.TradeReport{
        symbol: trading_symbol.symbol,
        position: trading_symbol.position,
        quantity_base: Decimal.new(1),
        quantity_quote: Decimal.new(1),
        quantity_fee: fee,
        fee_currency: "BNB"
      }
    end)
    # last trade trade 1:2. It should result in profit of capacity
    |> expect(:market_order, 1, fn trading_symbol, quantity ->
      %Types.TradeReport{
        symbol: trading_symbol.symbol,
        position: trading_symbol.position,
        quantity_base: Decimal.new(1),
        quantity_quote: Decimal.new(2),
        quantity_fee: fee,
        fee_currency: "BNB"
      }
    end)

    # must start with USDT, BNB balance must be negative in the end
    Balance.Exchange.TestMock
    |> expect(:get_balances, fn ->
      %{
        "USDT" => Decimal.new(100)
      }
    end)

    # Initialize MarketData
    market_data = MarketData.new()

    # Get trading paths and symbols
    {trading_paths, symbols} = MarketData.trading_paths(market_data, ["BTC", "ETH", "USDT"], 3)

    # Initialize components
    {:ok, _} = Balance.start_link()

    {:ok, _} = PriceStreamer.start_link(symbols)

    {:ok, _} =
      OpportunityWatcher.start_link(%OpportunityWatcher.Args{
        min_profit_percentage: Decimal.from_float(0.01),
        min_capacity: Decimal.from_float(0.01),
        commission: Decimal.from_float(0.001),
        trading_paths: trading_paths
      })

    {:ok, _} =
      PortfolioManager.start_link(%PortfolioManager.Args{
        relative_asset_values: MarketData.relative_values(market_data, "BTC")
      })

    number_of_traders = 1
    {:ok, _} = Trader.start_link(number_of_traders)

    # Simulate price updates
    # there should be multiple opportunities with capacity of 1
    PriceStreamer.price_update(%Types.PriceUpdate{
      symbol: "BTCUSDT",
      ask_price: Decimal.new(1),
      ask_qty: Decimal.new(1),
      bid_price: Decimal.new(1),
      bid_qty: Decimal.new(1)
    })

    PriceStreamer.price_update(%Types.PriceUpdate{
      symbol: "ETHBTC",
      ask_price: Decimal.new(1),
      ask_qty: Decimal.new(1),
      bid_price: Decimal.new(1),
      bid_qty: Decimal.new(1)
    })

    PriceStreamer.price_update(%Types.PriceUpdate{
      symbol: "ETHUSDT",
      ask_price: Decimal.new(1),
      ask_qty: Decimal.new(1),
      bid_price: Decimal.new(2),
      bid_qty: Decimal.new(2)
    })

    # allow time for execution
    :timer.sleep(100)

    assert Decimal.eq?(Balance.get("BTC"), Decimal.new(0))
    assert Decimal.eq?(Balance.get("ETH"), Decimal.new(0))
    assert Decimal.eq?(Balance.get("USDT"), Decimal.new(101))
    # 3 trades, with BNB fee each
    assert Decimal.eq?(Balance.get("BNB"), Decimal.mult(-3, fee))
  end

  defp swap_mock_and_get_old(key, new_module) do
    module = Application.get_env(:harjus, key)
    Application.put_env(:harjus, key, new_module)
    module
  end
end
