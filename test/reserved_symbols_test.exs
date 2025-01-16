defmodule ReservedSymbolsTest do
  @moduledoc """
  Tests for the Balance module
  """
  use ExUnit.Case
  doctest ReservedSymbols

  setup do
    {:ok, pid} = ReservedSymbols.start_link()
    %{pid: pid}
  end

  test "symbol can be reserved", %{pid: _pid} do
    symbol = ["BTCUSDT"]
    ReservedSymbols.reserve(symbol)
    assert ReservedSymbols.reserved?(symbol)
  end

  test "non-reserved symbols are free", %{pid: _pid} do
    assert !ReservedSymbols.reserved?(["ETHBTC"])
  end

  test "symbol can be released", %{pid: _pid} do
    symbol = ["DOGEUSDT"]
    ReservedSymbols.reserve(symbol)
    ReservedSymbols.release(symbol)
    assert !ReservedSymbols.reserved?(symbol)
  end
end
