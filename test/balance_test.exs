defmodule BalanceTest do
  @moduledoc """
  Tests for the Balance module
  """
  use ExUnit.Case
  doctest Balance

  setup do
    balance_map = %{
      "USDT" => Decimal.new("100.0"),
      "BTC" => Decimal.new("1.0")
    }

    {:ok, pid} = Balance.start_link(balance_map)
    %{pid: pid}
  end

  test "balances initialized correctly", %{pid: _pid} do
    assert Balance.get("USDT") == Decimal.new("100.0")
    assert Balance.get("BTC") == Decimal.new("1.0")
  end

  test "updates balances correctly", %{pid: _pid} do
    # add
    Balance.update("USDT", Decimal.new("50.0"))
    assert Balance.get("USDT") == Decimal.new("150.0")

    # subtract
    Balance.update("BTC", Decimal.new("-0.5"))
    assert Balance.get("BTC") == Decimal.new("0.5")
  end

  test "non-existent asset returns 0", %{pid: _pid} do
    assert Balance.get("ETH") == Decimal.new(0)
  end
end
