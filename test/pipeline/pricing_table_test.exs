defmodule Pipeline.PricingTableTest do
  @moduledoc """
  Tests for the Pricing table module
  """
  use ExUnit.Case, async: false
  doctest Balance

  alias Pipeline.PricingTable
  alias Types.TradingSymbol

  test "returns affected paths with correct price" do
    symbol = "BTCUSDT"

    ask_price = Decimal.new(100)
    ask_qty = Decimal.new(1)
    bid_price = Decimal.new(101)
    bid_qty = Decimal.new(2)

    pt =
      PricingTable.new([
        [ts_long(symbol)],
        [ts_short(symbol)],
        [ts_long("whatever")]
      ])

    {_new_pt, affected_paths} =
      PricingTable.update_get_affected(
        pt,
        {symbol, ask_price, ask_qty, bid_price, bid_qty}
      )

    # on long, ask price and qty are used
    # on short, bid price and qty are used
    assert affected_paths == [
             [ts(symbol, :long, ask_price, ask_qty)],
             [ts(symbol, :short, bid_price, bid_qty)]
           ]
  end

  test "returns affected paths, state persists" do
    symbol_btc = "BTCUSDT"
    symbol_eth = "ETHUSDT"

    ask_price = Decimal.new(100)
    ask_qty = Decimal.new(1)
    bid_price = Decimal.new(101)
    bid_qty = Decimal.new(2)

    pt =
      PricingTable.new([
        [ts_long(symbol_btc), ts_long(symbol_eth)],
        [ts_long(symbol_eth)]
      ])

    # update both symbol prices
    {new_pt, _affected_paths} =
      PricingTable.update_get_affected(
        pt,
        {symbol_btc, ask_price, ask_qty, bid_price, bid_qty}
      )

    {_new_pt, affected_paths} =
      PricingTable.update_get_affected(
        new_pt,
        {"ETHUSDT", ask_price, ask_qty, bid_price, bid_qty}
      )

    # now all prices should be the same
    assert affected_paths == [
             [
               ts(symbol_btc, :long, ask_price, ask_qty),
               ts(symbol_eth, :long, ask_price, ask_qty)
             ],
             [ts(symbol_eth, :long, ask_price, ask_qty)]
           ]
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
