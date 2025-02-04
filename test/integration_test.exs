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

  @tag :integration
  test "opportunity gets captured" do
    # Mock Binance modules
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
    |> expect(:market_order, 3, fn trading_symbol, quantity ->
      %Types.TradeReport{
        symbol: trading_symbol.symbol,
        position: trading_symbol.position,
        quantity_base: Decimal.new(1),
        quantity_quote: quantity,
        quantity_fee: Decimal.from_float(0.1),
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
    PriceStreamer.price_update(%Types.PriceUpdate{
      symbol: "BTCUSDT",
      ask_price: Decimal.new(10_000),
      ask_qty: Decimal.new(1),
      bid_price: Decimal.new(10_000),
      bid_qty: Decimal.new(1)
    })

    PriceStreamer.price_update(%Types.PriceUpdate{
      symbol: "ETHBTC",
      ask_price: Decimal.from_float(0.1),
      ask_qty: Decimal.new(1),
      bid_price: Decimal.from_float(0.1),
      bid_qty: Decimal.new(1)
    })

    PriceStreamer.price_update(%Types.PriceUpdate{
      symbol: "ETHUSDT",
      ask_price: Decimal.new(1_000),
      ask_qty: Decimal.new(1),
      bid_price: Decimal.new(1_000),
      bid_qty: Decimal.new(1)
    })

    # allow time for execution
    :timer.sleep(100)

    assert Decimal.eq?(Balance.get("BTC"), Decimal.new(1))
    assert Decimal.eq?(Balance.get("ETH"), Decimal.new(1))
    assert Decimal.eq?(Balance.get("USDT"), Decimal.new(10_000))
    assert Decimal.negative?(Balance.get("BNB"))
  end
end
