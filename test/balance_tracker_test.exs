defmodule BalanceTrackerTest do
  @moduledoc """
  Tests for the BalanceTracker module
  """
  use ExUnit.Case
  doctest BalanceTracker

  setup do
    balance_map = %{
      "USDT" => 100.0,
      "BTC" => 1.0
    }

    {:ok, pid} = BalanceTracker.start_link(balance_map)
    %{pid: pid}
  end

  test "balances initialized correctly", %{pid: _pid} do
    assert BalanceTracker.get_balance("USDT") == 100.0
    assert BalanceTracker.get_balance("BTC") == 1.0
  end

  test "updates balances correctly", %{pid: _pid} do
    # add
    BalanceTracker.update_balance("USDT", 50.0)
    assert BalanceTracker.get_balance("USDT") == 150.0

    # subtract
    BalanceTracker.update_balance("BTC", -0.5)
    assert BalanceTracker.get_balance("BTC") == 0.5
  end

  test "non-existent asset returns 0", %{pid: _pid} do
    assert BalanceTracker.get_balance("ETH") == 0
  end
end
