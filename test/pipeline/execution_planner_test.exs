defmodule Pipeline.ExecutionPlannerTest do
  @moduledoc """
  Tests for the Execution Planner module
  """

  alias Pipeline.ExecutionPlanner
  alias Types.PlannedExecution
  alias Types.TradingSymbol

  use ExUnit.Case, async: false
  doctest ExecutionPlanner

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
end
