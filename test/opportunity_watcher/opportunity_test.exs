defmodule OpportunityWatcher.OpportunityTest do
  @moduledoc "Tests for Opportunity"

  alias OpportunityWatcher.Opportunity
  alias Types.TradingSymbol

  use ExUnit.Case, async: true
  doctest Opportunity

  test "correct profit and capacity with 2 symbols" do
    commission = 0.0

    path = [
      %TradingSymbol{symbol: "BTCUSDT", position: :long, base_asset: "BTC", quote_asset: "USDT"},
      %TradingSymbol{symbol: "USDTBTC", position: :long, base_asset: "USDT", quote_asset: "BTC"}
    ]

    price_table = %{
      %TradingSymbol{symbol: "BTCUSDT", position: :long, base_asset: "BTC", quote_asset: "USDT"} =>
        {10_000.0, 1.0},
      %TradingSymbol{symbol: "USDTBTC", position: :long, base_asset: "USDT", quote_asset: "BTC"} =>
        {0.00005, 1337.1337},
      %TradingSymbol{symbol: "ETHBTC", position: :long, base_asset: "ETH", quote_asset: "BTC"} =>
        {0.1, 10.0},
      %TradingSymbol{symbol: "USDTETH", position: :long, base_asset: "USDT", quote_asset: "ETH"} =>
        {0.001, 1.0}
    }

    profit = Opportunity.profit(path, price_table, commission)
    capacity = Opportunity.capacity(path, price_table)

    assert profit == 1.0
    assert capacity == 1337.1337 / (1 + profit)
  end

  test "correct profit and capacity with 2 symbols (long + short)" do
    commission = 0.0

    path = [
      %TradingSymbol{symbol: "BTCUSDT", position: :long, base_asset: "BTC", quote_asset: "USDT"},
      %TradingSymbol{symbol: "BTCUSDT", position: :short, base_asset: "USDT", quote_asset: "BTC"}
    ]

    price_table = %{
      %TradingSymbol{symbol: "BTCUSDT", position: :long, base_asset: "BTC", quote_asset: "USDT"} =>
        {1.0, 1.0},
      %TradingSymbol{symbol: "BTCUSDT", position: :short, base_asset: "USDT", quote_asset: "BTC"} =>
        {2.0 ** -1, 1.0}
    }

    profit = Opportunity.profit(path, price_table, commission)
    capacity = Opportunity.capacity(path, price_table)

    assert profit == 1.0
    assert capacity == 0.5
  end

  test "correct profit and capacity with 3 symbols" do
    commission = 0.01

    path = [
      %TradingSymbol{symbol: "BTCUSDT", position: :long, base_asset: "BTC", quote_asset: "USDT"},
      %TradingSymbol{symbol: "ETHBTC", position: :long, base_asset: "ETH", quote_asset: "BTC"},
      %TradingSymbol{symbol: "USDTETH", position: :long, base_asset: "USDT", quote_asset: "ETH"}
    ]

    price_table = %{
      %TradingSymbol{symbol: "BTCUSDT", position: :long, base_asset: "BTC", quote_asset: "USDT"} =>
        {10_000.0, 1.0},
      %TradingSymbol{symbol: "ETHBTC", position: :long, base_asset: "ETH", quote_asset: "BTC"} =>
        {0.1, 10.0},
      %TradingSymbol{symbol: "USDTETH", position: :long, base_asset: "USDT", quote_asset: "ETH"} =>
        {0.001, 1.0}
    }

    profit = Opportunity.profit(path, price_table, commission)
    capacity = Opportunity.capacity(path, price_table)

    assert Float.round(profit, 4) == Float.round((1 - commission) ** length(path) - 1, 4)
    assert capacity == 1.0
  end

  test "empty path results in 0 profit" do
    profit = Opportunity.profit([], %{}, 0.1)

    assert profit == 0.0
  end

  test "empty price_quantity_map results in ArgumentError on capacity" do
    assert_raise ArgumentError, fn ->
      Opportunity.capacity([], %{})
    end
  end

  test "missing symbol in pricing results in ArgumentError" do
    assert_raise ArgumentError, fn ->
      Opportunity.profit(
        [
          %TradingSymbol{
            symbol: "BTCUSDT",
            position: :long,
            base_asset: "BTC",
            quote_asset: "USDT"
          },
          %TradingSymbol{
            symbol: "ETHBTC",
            position: :long,
            base_asset: "ETH",
            quote_asset: "BTC"
          },
          %TradingSymbol{
            symbol: "USDTETH",
            position: :long,
            base_asset: "USDT",
            quote_asset: "ETH"
          }
        ],
        %{
          %TradingSymbol{
            symbol: "BTCUSDT",
            position: :long,
            base_asset: "BTC",
            quote_asset: "USDT"
          } => {10_000.0, 1.0},
          %TradingSymbol{symbol: "ETHBTC", position: :long, base_asset: "ETH", quote_asset: "BTC"} =>
            {0.1, 10.0}
        },
        0.01
      )
    end
  end
end
