defmodule ReservedSymbolsTest do
  @moduledoc """
  Tests for the Balance module
  """
  use ExUnit.Case, async: false
  doctest ReservedSymbols

  setup do
    {:ok, _} = ReservedSymbols.start_link()
    :ok
  end

  ## Unit tests ##

  test "reserved_symbols returns empty list initially" do
    assert ReservedSymbols.get_reserved() == []
  end

  test "reserves symbols and releases them" do
    symbols = ["BTC", "ETH", "BNB"]
    partial_symbols = symbols |> Enum.take(2)

    ReservedSymbols.reserve_list!(symbols)
    result = ReservedSymbols.get_reserved()
    assert length(result) == length(symbols)
    assert Enum.all?(symbols, fn x -> Enum.member?(result, x) end)

    ReservedSymbols.release_list!(partial_symbols)
    second_result = ReservedSymbols.get_reserved()
    assert length(second_result) == 1
    assert Enum.member?(second_result, "BNB")
  end
end
