defmodule OpportunityTest do
  use ExUnit.Case, async: true
  doctest Opportunity

  test "correct profit and capacity with 2 symbols" do
    path = ["BTCUSDT", "USDTBTC"]

    price_table = %{
      "BTCUSDT" => %{best_ask: 10000.0, quantity: 1.0},
      "USDTBTC" => %{best_ask: 0.00005, quantity: 1337.1337},
      "ETHBTC" => %{best_ask: 0.1, quantity: 10.0},
      "USDTETH" => %{best_ask: 0.001, quantity: 1.0}
    }

    profit = Opportunity.profit(path, price_table)
    capacity = Opportunity.capacity(path, price_table, profit)

    assert profit == 1.0
    assert capacity == 1337.1337 / (1 + profit)
  end

  test "correct profit and capacity with 3 symbols" do
    path = ["BTCUSDT", "ETHBTC", "USDTETH"]

    price_table = %{
      "BTCUSDT" => %{best_ask: 10000.0, quantity: 1.0},
      "ETHBTC" => %{best_ask: 0.1, quantity: 10.0},
      "USDTETH" => %{best_ask: 0.001, quantity: 1.0}
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

  test "empty path results in KeyError on capacity" do
    assert_raise KeyError, fn ->
      Opportunity.capacity([], %{}, 1)
    end
  end

  test "missing symbol in pricing results in KeyError" do
    assert_raise KeyError, fn ->
      Opportunity.profit(["BTCUSDT", "ETHBTC", "USDTETH"], %{
        "BTCUSDT" => %{best_ask: 10000.0, quantity: 1.0},
        "ETHBTC" => %{best_ask: 0.1, quantity: 10.0}
      })
    end
  end
end
