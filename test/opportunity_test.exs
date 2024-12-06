defmodule OpportunityTest do
  use ExUnit.Case, async: true
  doctest Opportunity

  test "generates correct opportunity" do
    result =
      Opportunity.triangular_arbitrage(["BTCUSDT", "ETHBTC", "USDTETH"], %{
        "BTCUSDT" => %{best_ask: 10000.0, quantity: 1.0},
        "ETHBTC" => %{best_ask: 0.1, quantity: 10.0},
        "USDTETH" => %{best_ask: 1000.0, quantity: 1.0}
      })

    assert result == %{profit: 0.0, capacity: 1.0}
  end

  test "empty path results in KeyError" do
    assert_raise KeyError, fn ->
      Opportunity.triangular_arbitrage([], %{})
    end
  end

  test "missing symbol in pricing results in KeyError" do
    assert_raise KeyError, fn ->
      Opportunity.triangular_arbitrage(["BTCUSDT", "ETHBTC", "USDTETH"], %{
        "BTCUSDT" => %{best_ask: 10000.0, quantity: 1.0},
        "ETHBTC" => %{best_ask: 0.1, quantity: 10.0}
      })
    end
  end
end
