defmodule Trader.BalanceDeltaTest do
  @moduledoc "Tests for BalanceDelta"

  use ExUnit.Case
  use PropCheck

  alias Trader.BalanceDelta
  alias Types.TradeReport
  alias Types.TradingSymbol

  property "resulting delta contains same gte number of symbols" do
    forall [delta, {trading_symbol, trade_report}] <- [delta(), trading_symbol_and_trade_report()] do
      new_delta = BalanceDelta.update_balance_delta(delta, trading_symbol, trade_report)
      assert map_size(new_delta) >= map_size(delta)
    end
  end

  property "updates balance correctly" do
    forall [delta, {trading_symbol, trade_report}] <- [delta(), trading_symbol_and_trade_report()] do
      new_delta = BalanceDelta.update_balance_delta(delta, trading_symbol, trade_report)

      quote_asset = trading_symbol.quote_asset
      base_asset = trading_symbol.base_asset

      new_quote_qty = Map.get(new_delta, quote_asset)
      new_base_qty = Map.get(new_delta, base_asset)

      old_quote_qty = Map.get(delta, quote_asset, Decimal.new(0))
      old_base_qty = Map.get(delta, base_asset, Decimal.new(0))

      result =
        case(trading_symbol.position) do
          :long ->
            Decimal.lte?(new_quote_qty, old_quote_qty) && Decimal.gte?(new_base_qty, old_base_qty)

          :short ->
            Decimal.gte?(new_quote_qty, old_quote_qty) && Decimal.lte?(new_base_qty, old_base_qty)
        end

      assert result
    end
  end

  ### generators

  defp trading_symbol_and_trade_report do
    let [trading_symbol <- trading_symbol()] do
      {trading_symbol, trade_report(trading_symbol)}
    end
  end

  defp trade_report(trading_symbol) do
    let [
      quantity_base <- pos_decimal(),
      quantity_quote <- pos_decimal()
    ] do
      %TradeReport{
        symbol: trading_symbol.symbol,
        position: trading_symbol.position,
        quantity_base: quantity_base,
        quantity_quote: quantity_quote,
        fees: []
      }
    end
  end

  defp delta do
    let [list_of_asset_qtys <- non_empty(list(asset_qty()))] do
      Map.new(list_of_asset_qtys, fn {asset, qty} -> {asset, qty} end)
    end
  end

  defp asset_qty do
    let [asset <- non_empty_string(), qty <- pos_decimal()] do
      {asset, qty}
    end
  end

  defp trading_symbol do
    let [
      symbol <- non_empty_string(),
      base_asset <- non_empty_string(),
      min_notional <- pos_decimal(),
      position <- position(),
      qty <- pos_decimal(),
      price <- pos_decimal()
    ] do
      %TradingSymbol{
        symbol: symbol,
        base_asset: base_asset,
        quote_asset: "#{base_asset}2",
        base_asset_precision: 8,
        quote_asset_precision: 8,
        base_asset_increment: Decimal.from_float(0.000001),
        quote_asset_increment: Decimal.from_float(0.000001),
        min_notional: min_notional,
        position: position,
        qty: qty,
        price: price
      }
    end
  end

  defp position do
    let pos <- union([:long, :short]) do
      pos
    end
  end

  defp pos_decimal do
    let float <- float(0.000001, :inf) do
      Decimal.from_float(float)
    end
  end

  defp non_empty_string do
    let charlist <- non_empty(elements(textdata())) do
      to_string(charlist)
    end
  end

  defp textdata do
    ~c"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789" ++
      ~c":;<=>?@ !#$%&'()*+-./[\\]^_`{|}~"
  end

  # unit test

  test "updates balance correctly on long" do
    trading_symbol = %TradingSymbol{
      symbol: "BTCUSDT",
      base_asset: "BTC",
      quote_asset: "USDT",
      base_asset_precision: 8,
      quote_asset_precision: 8,
      base_asset_increment: Decimal.from_float(0.000001),
      quote_asset_increment: Decimal.from_float(0.000001),
      min_notional: Decimal.new(10),
      position: :long,
      qty: Decimal.new(0),
      price: Decimal.new(0)
    }

    trade_report = %TradeReport{
      symbol: "BTCUSDT",
      position: :long,
      quantity_base: Decimal.from_float(0.1),
      quantity_quote: Decimal.new(1000),
      fees: []
    }

    assert_result(%{}, trading_symbol, trade_report)
  end

  test "updates balance correctly on short" do
    trading_symbol = %TradingSymbol{
      symbol: "BTCUSDT",
      base_asset: "BTC",
      quote_asset: "USDT",
      base_asset_precision: 8,
      quote_asset_precision: 8,
      base_asset_increment: Decimal.from_float(0.000001),
      quote_asset_increment: Decimal.from_float(0.000001),
      min_notional: Decimal.new(10),
      position: :short,
      qty: Decimal.new(0),
      price: Decimal.new(0)
    }

    trade_report = %TradeReport{
      symbol: "BTCUSDT",
      position: :short,
      quantity_base: Decimal.from_float(0.1),
      quantity_quote: Decimal.new(1000),
      fees: []
    }

    assert_result(%{}, trading_symbol, trade_report)
  end

  test "new returns empty map" do
    assert BalanceDelta.new() == %{}
  end

  test "increment_balance_delta increments correctly" do
    delta = %{"BTC" => Decimal.new(1)}
    symbol = "BTC"
    amount = Decimal.new(1)

    new_delta = BalanceDelta.increment_balance_delta(delta, symbol, amount)

    assert new_delta == %{"BTC" => Decimal.new(2)}

    another_symbol = "Anothersymbol"
    another_delta = BalanceDelta.increment_balance_delta(new_delta, another_symbol, amount)

    assert another_delta == %{"BTC" => Decimal.new(2), another_symbol => amount}
  end

  defp assert_result(delta, trading_symbol, trade_report) do
    new_delta = BalanceDelta.update_balance_delta(delta, trading_symbol, trade_report)

    quote_asset = trading_symbol.quote_asset
    base_asset = trading_symbol.base_asset

    new_quote_qty = Map.get(new_delta, quote_asset)
    new_base_qty = Map.get(new_delta, base_asset)

    old_quote_qty = Map.get(delta, quote_asset, Decimal.new(0))
    old_base_qty = Map.get(delta, base_asset, Decimal.new(0))

    result =
      case(trading_symbol.position) do
        :long ->
          Decimal.lte?(new_quote_qty, old_quote_qty) && Decimal.gte?(new_base_qty, old_base_qty)

        :short ->
          Decimal.gte?(new_quote_qty, old_quote_qty) && Decimal.lte?(new_base_qty, old_base_qty)
      end

    assert result
  end
end
