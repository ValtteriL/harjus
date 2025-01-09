defmodule BalanceTest do
  @moduledoc """
  Tests for the Balance module
  """
  use ExUnit.Case
  doctest Balance

  setup do
    balance_map = %{
      "USDT" => 100.0,
      "BTC" => 1.0
    }

    {:ok, pid} = Balance.start_link(balance_map)
    %{pid: pid}
  end

  test "balances initialized correctly", %{pid: _pid} do
    assert Balance.get_balance("USDT") == 100.0
    assert Balance.get_balance("BTC") == 1.0
  end

  test "updates balances correctly", %{pid: _pid} do
    # add
    Balance.update_balance("USDT", 50.0)
    assert Balance.get_balance("USDT") == 150.0

    # subtract
    Balance.update_balance("BTC", -0.5)
    assert Balance.get_balance("BTC") == 0.5
  end

  test "non-existent asset returns 0", %{pid: _pid} do
    assert Balance.get_balance("ETH") == 0
  end
end
