defmodule BalanceTest do
  @moduledoc """
  Tests for the Balance module
  """
  use ExUnit.Case
  doctest Balance
  use PropCheck

  setup do
    {:ok, _pid} = Balance.start_link()
    :ok
  end

  property "balance behaves correctly", [:verbose] do
    forall [symbol, update_value] <- [non_empty_string(), float()] do
      # starting balance is 0
      assert Balance.get(symbol) == Decimal.new(0)

      # balance is updated correctly
      :ok = Balance.update(symbol, Decimal.from_float(update_value))
      assert Balance.get(symbol) == Decimal.from_float(update_value)

      # reserve upto the current balance
      {reserved, _} = Balance.reserve_upto(symbol, Decimal.from_float(update_value))

      # reserved amount is the same as the current balance
      assert reserved == Decimal.from_float(update_value)

      # balance is now 0
      assert Balance.get(symbol) == Decimal.new(0)
    end
  end

  ## Generators ##

  defp non_empty_string do
    let charlist <- non_empty(elements(textdata())) do
      to_string(charlist)
    end
  end

  defp textdata do
    ~c"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789" ++
      ~c":;<=>?@ !#$%&'()*+-./[\\]^_`{|}~"
  end

  ## Unit tests ##

  test "updates balances correctly" do
    symbol = "SOMETHING_COOL"

    # add
    Balance.update(symbol, Decimal.new("50.0"))
    assert Balance.get(symbol) == Decimal.new("50.0")

    # subtract
    Balance.update(symbol, Decimal.new("-25.0"))
    assert Balance.get(symbol) == Decimal.new("25.0")
  end

  test "non-existent asset returns 0" do
    assert Balance.get("this-does-not-exist") == Decimal.new(0)
  end
end
