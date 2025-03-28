defmodule Pipeline.ExecutionPlannerTest do
  @moduledoc """
  Tests for the Execution Planner module
  """

  alias Pipeline.ExecutionPlanner
  alias Types.PlannedExecution
  alias Types.TradingSymbol

  use ExUnit.Case, async: false
  use PropCheck
  doctest ExecutionPlanner

  # property: recalc contains same number of trades with only qty changed, total profit changed
  # new qties lte old qties
  # for every trade, used balance lte received balance

  property "behaves as intended" do
    forall [
             old_plan,
             starting_asset_balance
           ] <- [
             planned_execution(),
             pos_decimal()
           ] do
      new_plan = ExecutionPlanner.recalculate_with_balance(old_plan, starting_asset_balance)

      # number of trades is invariant
      assert length(new_plan.trades) == length(old_plan.trades)

      # total profit cannot grow
      assert Decimal.lte?(new_plan.total_profit, old_plan.total_profit)

      pairs = Enum.zip(old_plan.trades, new_plan.trades)

      # new first trade qty lte old qty
      assert Decimal.lte?(Enum.at(new_plan.trades, 0).qty, Enum.at(old_plan.trades, 0).qty)

      # new trades are identical to old trades except for qty
      assert Enum.all?(pairs, fn {old_trade, new_trade} ->
               Map.equal?(old_trade, Map.put(new_trade, :qty, old_trade.qty))
             end)

      # for every new trade, used balance lte received balance
      assert Enum.reduce_while(new_plan.trades, starting_asset_balance, fn trade, budget ->
               used_balance =
                 case trade.position do
                   :long -> Decimal.mult(trade.price, trade.qty)
                   :short -> trade.qty
                 end

               received_balance =
                 case trade.position do
                   :long -> trade.qty
                   :short -> Decimal.mult(trade.price, trade.qty)
                 end

               cond do
                 Decimal.gt?(used_balance, budget) ->
                   {:halt, false}

                 # if last trade, return true
                 Enum.at(new_plan.trades, -1) == trade ->
                   {:halt, true}

                 true ->
                   {:cont, received_balance}
               end
             end)
    end
  end

  test "returns correct execution plan" do
    # path that allows for 1 BTC profit
    path = [
      ts("BTCUSDT", :short, Decimal.new(1), Decimal.new(2)),
      ts("ETHUSDT", :long, Decimal.new(1), Decimal.new(1)),
      ts("BTCETH", :long, Decimal.from_float(0.5), Decimal.new(2))
    ]

    old_plan = %PlannedExecution{
      total_profit: Decimal.new(2),
      trades: path
    }

    starting_asset_balance = Decimal.new(1)

    plan =
      ExecutionPlanner.recalculate_with_balance(
        old_plan,
        starting_asset_balance
      )

    # total profit is old/2 as we have half the qty
    assert Decimal.eq?(plan.total_profit, 1)
    assert length(plan.trades) == 3
    assert %PlannedExecution{} = plan

    assert Enum.map(plan.trades, fn x -> {x.symbol, x.position} end) == [
             {"BTCUSDT", :short},
             {"ETHUSDT", :long},
             {"BTCETH", :long}
           ]
  end

  test "total_profit 0 if balance is 0" do
    path = [
      ts("BTCUSDT", :short, Decimal.new(1), Decimal.new(1))
    ]

    starting_asset_balance = Decimal.new(0)

    old_plan = %PlannedExecution{
      total_profit: Decimal.new(1),
      trades: path
    }

    plan =
      ExecutionPlanner.recalculate_with_balance(
        old_plan,
        starting_asset_balance
      )

    assert Decimal.eq?(plan.total_profit, 0)
  end

  ## helpers

  defp ts(symbol, position, price, qty) do
    %TradingSymbol{
      symbol: symbol,
      position: position,
      base_asset: "#{symbol}_base",
      quote_asset: "#{symbol}_quote",
      base_asset_increment: Decimal.from_float(0.001),
      base_asset_precision: 8,
      quote_asset_increment: Decimal.from_float(0.001),
      quote_asset_precision: 8,
      min_notional: Decimal.new(0),
      price: price,
      qty: qty
    }
  end

  ## Generators ##

  defp planned_execution do
    let([
      total_profit <- pos_decimal(),
      trades <- non_empty(list(trade()))
    ]) do
      %PlannedExecution{
        total_profit: total_profit,
        trades: trades
      }
    end
  end

  defp trade do
    let([
      symbol <- non_empty_string(),
      position <- elements([:long, :short]),
      base_asset <- non_empty_string(),
      quote_asset <- non_empty_string(),
      base_asset_precision <- pos_integer(),
      quote_asset_precision <- pos_integer(),
      base_asset_increment <- pos_decimal(),
      quote_asset_increment <- pos_decimal(),
      min_notional <- pos_decimal(),
      price <- pos_decimal(),
      qty <- pos_decimal()
    ]) do
      %TradingSymbol{
        symbol: symbol,
        position: position,
        base_asset: base_asset,
        quote_asset: quote_asset,
        base_asset_precision: base_asset_precision,
        quote_asset_precision: quote_asset_precision,
        base_asset_increment: base_asset_increment,
        quote_asset_increment: quote_asset_increment,
        min_notional: min_notional,
        price: price,
        qty: qty
      }
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

  defp pos_decimal do
    let float <- float(0.000001, :inf) do
      Decimal.from_float(float)
    end
  end
end
