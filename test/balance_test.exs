defmodule BalanceTest do
  @moduledoc """
  Tests for the Balance module
  """
  use ExUnit.Case, async: false
  doctest Balance

  import Mox

  # use global Mox mode
  setup :set_mox_from_context
  setup :verify_on_exit!

  ## Unit tests ##

  test "starting balances returns empty map" do
    Balance.Exchange.TestMock
    |> expect(:get_balances, fn -> %{} end)

    {:ok, _} = Balance.start_link()

    assert Balance.get_balances() == %{}
  end

  test "reserve decrements balance" do
    Balance.Exchange.TestMock
    |> expect(:get_balances, fn -> %{"BTC" => Decimal.from_float(1.0)} end)

    {:ok, _} = Balance.start_link()

    assert Balance.reserve!("BTC", Decimal.from_float(0.5)) == :ok
    assert Balance.get_balances() == %{"BTC" => Decimal.from_float(0.5)}
  end

  test "release increments balance" do
    Balance.Exchange.TestMock
    |> expect(:get_balances, fn -> %{"BTC" => Decimal.from_float(1.0)} end)

    {:ok, _} = Balance.start_link()

    assert Balance.release(%{"BTC" => Decimal.from_float(0.5)}) == :ok
    assert Balance.get_balances() == %{"BTC" => Decimal.from_float(1.5)}
  end
end
