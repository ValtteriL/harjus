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
          quoteAssetIncrement: Decimal.from_float(0.01),
          minNotional: Decimal.from_float(0.0001)
        },
        %Symbol{
          symbol: "ETHBTC",
          baseAsset: "ETH",
          quoteAsset: "BTC",
          baseAssetPrecision: 8,
          quoteAssetPrecision: 2,
          baseAssetIncrement: Decimal.from_float(0.000001),
          quoteAssetIncrement: Decimal.from_float(0.01),
          minNotional: Decimal.from_float(0.0001)
        },
        %Symbol{
          symbol: "USDTETH",
          baseAsset: "USDT",
          quoteAsset: "ETH",
          baseAssetPrecision: 8,
          quoteAssetPrecision: 2,
          baseAssetIncrement: Decimal.from_float(0.000001),
          quoteAssetIncrement: Decimal.from_float(0.01),
          minNotional: Decimal.from_float(0.0001)
        }
      ]
    end)
    |> expect(:get_symbol_prices, fn ->
      %{
        "BTCUSDT" => Decimal.from_float(10_000.0),
        "ETHBTC" => Decimal.from_float(0.1),
        "USDTETH" => Decimal.from_float(0.001)
      }
    end)

    TradeClient.Exchange.TestMock
    |> expect(:new, fn ->
      {:ok, self()}
    end)
    # trades
    |> expect(:limit_order, 3, fn trading_symbol, quantity, price ->
      {:executed,
       %Types.TradeReport{
         symbol: trading_symbol.symbol,
         position: trading_symbol.position,
         quantity_base: quantity,
         quantity_quote: Decimal.mult(quantity, price),
         fees: [
           %Types.TradeReport.Fee{
             fee_currency: "BNB",
             fee_amount: fee
           }
         ]
       }}
    end)

    # must start with USDT, BNB
    Balance.Exchange.TestMock
    |> expect(:get_balances, fn ->
      %{
        "USDT" => Decimal.new(100),
        "BNB" => Decimal.new(100)
      }
    end)

    # Initialize MarketData
    market_data = MarketData.new()

    # Get trading paths and symbols
    {trading_paths, symbols} = MarketData.trading_paths(market_data, ["BTC", "ETH", "USDT"], 3)

    # Initialize components
    {:ok, _} = Balance.start_link([])

    {:ok, _} = ReservedSymbols.start_link([])

    {:ok, _} = Task.Supervisor.start_link(name: TraderSupervisor)

    {:ok, _} = TradeClient.start_link([])

    commission = Decimal.from_float(0.001)
    relative_asset_values = MarketData.relative_values(market_data, "BTC")
    {:ok, _} = Pipeline.start_link({trading_paths, commission, relative_asset_values})

    {:ok, _} = PriceStreamer.start_link(symbols)

    # Simulate price updates
    # there should be multiple opportunities with capacity of 1
    Pipeline.price_update(
      "BTCUSDT",
      Decimal.new(1),
      Decimal.new(1),
      Decimal.new(1),
      Decimal.new(1)
    )

    Pipeline.price_update(
      "ETHBTC",
      Decimal.new(1),
      Decimal.new(1),
      Decimal.new(1),
      Decimal.new(1)
    )

    Pipeline.price_update(
      "USDTETH",
      Decimal.new("0.5"),
      Decimal.new(2),
      Decimal.new(1),
      Decimal.new(1)
    )

    # allow time for execution
    :timer.sleep(100)

    balances = Balance.get_balances()

    assert Decimal.eq?(Map.fetch!(balances, "BTC"), Decimal.new(0))
    assert Decimal.eq?(Map.fetch!(balances, "ETH"), Decimal.new(0))
    assert Decimal.eq?(Map.fetch!(balances, "USDT"), Decimal.new(101))
    # 3 trades, with BNB fee each
    assert Decimal.lt?(Map.fetch!(balances, "BNB"), Decimal.new(100))
  end

  defp swap_mock_and_get_old(key, new_module) do
    module = Application.get_env(:harjus, key)
    Application.put_env(:harjus, key, new_module)
    module
  end
end
