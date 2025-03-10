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
      ts("BTCUSDT", :short, Decimal.new(1), Decimal.new(1)),
      ts("ETHUSDT", :long, Decimal.new(1), Decimal.new(1)),
      ts("BTCETH", :long, Decimal.from_float(0.5), Decimal.new(2))
    ]

    starting_asset_balance = Decimal.new(1)
    commission_percentage = Decimal.from_float(0.1)

    # BTC relative value is 3, ETH 2, USDT 1
    relative_asset_values = %{
      "BTCUSDT_base" => Decimal.new(3),
      "BTCUSDT_quote" => Decimal.new(1),
      "ETHUSDT_base" => Decimal.new(2),
      "ETHUSDT_quote" => Decimal.new(1),
      "BTCETH_base" => Decimal.new(3),
      "BTCETH_quote" => Decimal.new(2)
    }

    plan =
      ExecutionPlanner.plan_execution(
        path,
        starting_asset_balance,
        commission_percentage,
        relative_asset_values
      )

    # total profit is nBTC * relative value of BTC
    # nBTC = (1 * (1-0.1) * 1 * (1-0.1) * 2 * (1-0.1)) - 1 = 0,458 // 0.1 is the commission percentage
    # relative value of BTC = 3
    # total profit = 1.374
    assert Decimal.eq?(plan.total_profit, "1.374")
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
    commission_percentage = Decimal.new(0)

    relative_asset_values = %{"BTCUSDT_base" => Decimal.new(3), "BTCUSDT_quote" => Decimal.new(1)}

    plan =
      ExecutionPlanner.plan_execution(
        path,
        starting_asset_balance,
        commission_percentage,
        relative_asset_values
      )

    assert Decimal.eq?(plan.total_profit, 0)
  end

  test "total_profit 0 if capacity is less than notional" do
    symbol = "BTCUSDT"
    min_notional = Decimal.new(2)

    path = [
      %TradingSymbol{
        symbol: symbol,
        position: :short,
        base_asset: "#{symbol}_base",
        quote_asset: "#{symbol}_quote",
        base_asset_increment: Decimal.from_float(0.001),
        base_asset_precision: 8,
        quote_asset_increment: Decimal.from_float(0.001),
        quote_asset_precision: 8,
        min_notional: min_notional,
        price: Decimal.new(1),
        qty: Decimal.new(1)
      }
    ]

    starting_asset_balance = Decimal.new(100)
    commission_percentage = Decimal.new(0)

    relative_asset_values = %{"BTCUSDT_base" => Decimal.new(3), "BTCUSDT_quote" => Decimal.new(1)}

    plan =
      ExecutionPlanner.plan_execution(
        path,
        starting_asset_balance,
        commission_percentage,
        relative_asset_values
      )

    assert Decimal.eq?(plan.total_profit, 0)
  end

  test "raises error if used currency does not have relative value" do
    path = [
      ts("BTCUSDT", :short, Decimal.new(1), Decimal.new(1))
    ]

    starting_asset_balance = Decimal.new(1)
    commission_percentage = Decimal.new(0)

    relative_asset_values = %{}

    assert_raise KeyError, fn ->
      ExecutionPlanner.plan_execution(
        path,
        starting_asset_balance,
        commission_percentage,
        relative_asset_values
      )
    end
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
