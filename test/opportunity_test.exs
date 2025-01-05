defmodule OpportunityTest do
  @moduledoc "Tests for Opportunity"
  use ExUnit.Case, async: true
  doctest Opportunity

  test "correct profit and capacity with 2 symbols" do
    path = [
      %TradingSymbol{symbol: "BTCUSDT", position: :long},
      %TradingSymbol{symbol: "USDTBTC", position: :long}
    ]

    price_table = %{
      %TradingSymbol{symbol: "BTCUSDT", position: :long} => {10_000.0, 1.0},
      %TradingSymbol{symbol: "USDTBTC", position: :long} => {0.00005, 1337.1337},
      %TradingSymbol{symbol: "ETHBTC", position: :long} => {0.1, 10.0},
      %TradingSymbol{symbol: "USDTETH", position: :long} => {0.001, 1.0}
    }

    profit = Opportunity.profit(path, price_table)
    capacity = Opportunity.capacity(path, price_table, profit)

    assert profit == 1.0
    assert capacity == 1337.1337 / (1 + profit)
  end

  test "correct profit and capacity with 2 symbols (long + short)" do
    path = [
      %TradingSymbol{symbol: "BTCUSDT", position: :long},
      %TradingSymbol{symbol: "BTCUSDT", position: :short}
    ]

    price_table = %{
      %TradingSymbol{symbol: "BTCUSDT", position: :long} => {1.0, 1.0},
      %TradingSymbol{symbol: "BTCUSDT", position: :short} => {2.0 ** -1, 1.0}
    }

    profit = Opportunity.profit(path, price_table)
    capacity = Opportunity.capacity(path, price_table, profit)

    assert profit == 1.0
    assert capacity == 0.5
  end

  test "correct profit and capacity with 3 symbols" do
    path = [
      %TradingSymbol{symbol: "BTCUSDT", position: :long},
      %TradingSymbol{symbol: "ETHBTC", position: :long},
      %TradingSymbol{symbol: "USDTETH", position: :long}
    ]

    price_table = %{
      %TradingSymbol{symbol: "BTCUSDT", position: :long} => {10_000.0, 1.0},
      %TradingSymbol{symbol: "ETHBTC", position: :long} => {0.1, 10.0},
      %TradingSymbol{symbol: "USDTETH", position: :long} => {0.001, 1.0}
    }

    profit = Opportunity.profit(path, price_table)
    capacity = Opportunity.capacity(path, price_table, profit)

    assert profit == 0.0
    assert capacity == 1.0
  end

  test "empty path results in 0 profit" do
    profit = Opportunity.profit([], %{})

    assert profit == 0.0
  end

  test "empty price_quantity_map results in ArgumentError on capacity" do
    assert_raise ArgumentError, fn ->
      Opportunity.capacity([], %{}, 1)
    end
  end

  test "missing symbol in pricing results in ArgumentError" do
    assert_raise ArgumentError, fn ->
      Opportunity.profit(
        [
          %TradingSymbol{symbol: "BTCUSDT", position: :long},
          %TradingSymbol{symbol: "ETHBTC", position: :long},
          %TradingSymbol{symbol: "USDTETH", position: :long}
        ],
        %{
          %TradingSymbol{symbol: "BTCUSDT", position: :long} => {10_000.0, 1.0},
          %TradingSymbol{symbol: "ETHBTC", position: :long} => {0.1, 10.0}
        }
      )
    end
  end
end
