defmodule BalanceTest do
  @moduledoc """
  Tests for the Balance module
  """
  use ExUnit.Case
  doctest Balance

  setup do
    {:ok, pid} = Balance.start_link()
    %{pid: pid}
  end

  test "updates balances correctly", %{pid: _pid} do
    symbol = "SOMETHING_COOL"

    # add
    Balance.update(symbol, Decimal.new("50.0"))
    assert Balance.get(symbol) == Decimal.new("50.0")

    # subtract
    Balance.update(symbol, Decimal.new("-25.0"))
    assert Balance.get(symbol) == Decimal.new("25.0")
  end

  test "non-existent asset returns 0", %{pid: _pid} do
    assert Balance.get("this-does-not-exist") == Decimal.new(0)
  end
end
