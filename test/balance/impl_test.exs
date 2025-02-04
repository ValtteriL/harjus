defmodule Balance.ImplTest do
  @moduledoc "Tests for Impl"

  use ExUnit.Case, async: true

  alias Balance.Impl

  use PropCheck
  import Mox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  property "starting balance is 0" do
    forall [symbol] <- [
             non_empty_string()
           ] do
      Balance.Exchange.TestMock
      |> expect(:get_balances, fn -> %{} end)

      state = Impl.new()

      # starting balance is 0
      assert Decimal.eq?(Impl.get(state, symbol), Decimal.from_float(0.0))
    end
  end

  property "balance is updated correctly" do
    forall [symbol, update_value] <- [
             non_empty_string(),
             decimal()
           ] do
      Balance.Exchange.TestMock
      |> expect(:get_balances, fn -> %{} end)

      state = Impl.new()

      # balance is updated correctly
      state = Impl.update(state, symbol, update_value)
      assert Decimal.eq?(Impl.get(state, symbol), update_value)
    end
  end

  property "return value is multiplier of increment" do
    forall [symbol, balance, increment, precision] <- [
             non_empty_string(),
             pos_decimal(),
             pos_decimal(),
             pos_integer()
           ] do
      Balance.Exchange.TestMock
      |> expect(:get_balances, fn -> %{} end)

      state = Impl.new()

      # reserve upto the current balance
      {reserved, _state} =
        Impl.reserve_upto(state, symbol, balance, increment, precision)

      # reserved amount is a multiple of increment
      assert Decimal.eq?(Decimal.rem(reserved, increment), Decimal.new(0))
    end
  end

  property "return value has precision number of decimals" do
    forall [symbol, balance, increment, precision] <- [
             non_empty_string(),
             pos_decimal(),
             pos_decimal(),
             integer(0, 15)
           ] do
      Balance.Exchange.TestMock
      |> expect(:get_balances, fn -> %{symbol => balance} end)

      state = Impl.new()

      # reserve upto the current balance
      {reserved, _state} =
        Impl.reserve_upto(state, symbol, balance, increment, precision)

      # reserved amount has the specified number of decimals
      assert Decimal.scale(reserved) == precision
    end
  end

  property "return value is less than or equal to balance" do
    forall [symbol, balance, increment, precision] <- [
             non_empty_string(),
             pos_decimal(),
             pos_decimal(),
             pos_integer()
           ] do
      Balance.Exchange.TestMock
      |> expect(:get_balances, fn -> %{symbol => balance} end)

      state = Impl.new()

      # reserve upto the current balance
      {reserved, _state} =
        Impl.reserve_upto(state, symbol, balance, increment, precision)

      # reserved amount is less than or equal to balance
      assert Decimal.lte?(reserved, balance)
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

  defp pos_decimal do
    let float <- float(0.000001, :inf) do
      Decimal.from_float(float)
    end
  end

  defp decimal do
    let float <- float() do
      Decimal.from_float(float)
    end
  end
end
