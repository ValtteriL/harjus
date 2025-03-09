defmodule ReservedSymbolsTest do
  @moduledoc """
  Tests for the Balance module
  """
  use ExUnit.Case, async: false
  doctest ReservedSymbols

  alias Types.TradingSymbol

  setup do
    {:ok, _} = ReservedSymbols.start_link()
    :ok
  end

  ## Unit tests ##

  test "reserved_symbols returns empty list initially" do
    assert ReservedSymbols.get_reserved() == []
  end

  test "reserves symbols and releases them" do
    symbols = [ts_long("BTCETH"), ts_short("ETHUSDT"), ts_long("BNBUSDT")]
    partial_symbols = symbols |> Enum.take(2)

    ReservedSymbols.reserve_list!(symbols)
    result = ReservedSymbols.get_reserved()
    assert length(result) == length(symbols)

    symbols
    |> Enum.map(fn s -> {s.symbol, s.position} end)
    |> Enum.all?(fn x -> Enum.member?(result, x) end)

    ReservedSymbols.release_list!(partial_symbols)
    second_result = ReservedSymbols.get_reserved()
    assert length(second_result) == 1
    assert Enum.member?(second_result, {"BNBUSDT", :long})
  end

  test "symbols can be reserved for long and short" do
    symbols = [ts_long("BTCETH"), ts_short("BTCETH")]

    ReservedSymbols.reserve_list!(symbols)
    result = ReservedSymbols.get_reserved()
    assert length(result) == length(symbols)

    symbols
    |> Enum.map(fn s -> {s.symbol, s.position} end)
    |> Enum.all?(fn x -> Enum.member?(result, x) end)
  end

  ## helpers

  defp ts_long(symbol) do
    ts(symbol, :long, Decimal.new(0), Decimal.new(0))
  end

  defp ts_short(symbol) do
    ts(symbol, :short, Decimal.new(0), Decimal.new(0))
  end

  defp ts(symbol, position, price, qty) do
    %TradingSymbol{
      symbol: symbol,
      position: position,
      base_asset: "#{symbol}_base",
      quote_asset: "#{symbol}_quote",
      base_asset_increment: Decimal.new(0),
      base_asset_precision: 8,
      quote_asset_increment: Decimal.new(0),
      quote_asset_precision: 8,
      min_notional: Decimal.new(0),
      price: price,
      qty: qty
    }
  end
end
