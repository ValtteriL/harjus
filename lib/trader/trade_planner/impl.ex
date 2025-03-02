defmodule Trader.TradePlanner.Impl do
  @moduledoc """
  Implementation of the trade planner
  """

  require Decimal

  alias Types.Opportunity
  alias Types.PlannedTrade
  alias Types.TradingSymbol

  @spec plan_execution(Opportunity.t(), Decimal.t()) ::
          {:ok, [PlannedTrade.t()]} | {:insufficient_balance, any()}
  def plan_execution(
        %Opportunity{
          path: path = [%PlannedTrade{} | _],
          capacity: full_capacity
        },
        budget
      ) do
    # plan valid qty, price for each trade in opportunity based on budget
    capacity = Decimal.min(full_capacity, budget)

    plan =
      path
      |> Enum.map_reduce(capacity, fn pt, acc ->
        {order_qty, received_qty} =
          order_qty_received_qty_for_budget(acc, pt.order_price, pt.trading_symbol)

        {
          %PlannedTrade{
            trading_symbol: pt.trading_symbol,
            order_price: pt.order_price,
            order_qty: order_qty
          },
          received_qty
        }
      end)
      |> elem(0)

    # ensure all trades have notional >= min_notional
    notional_fulfilled =
      plan
      |> Enum.all?(fn pt ->
        notional = Decimal.mult(pt.order_qty, pt.order_price)
        Decimal.gt?(notional, pt.trading_symbol.min_notional)
      end)

    if notional_fulfilled do
      {:ok, plan}
    else
      {:insufficient_balance, nil}
    end
  end

  # ensure qty is a multiple of base_asset_increment
  defp order_qty_received_qty_for_budget(
         budget,
         price,
         trading_symbol = %TradingSymbol{position: :long}
       ) do
    order_qty =
      Decimal.div(budget, price)
      |> Decimal.div_int(trading_symbol.base_asset_increment)
      |> Decimal.mult(trading_symbol.base_asset_increment)

    {order_qty, order_qty}
  end

  defp order_qty_received_qty_for_budget(
         budget,
         price,
         trading_symbol = %TradingSymbol{position: :short}
       ) do
    order_qty =
      budget
      |> Decimal.div_int(trading_symbol.base_asset_increment)
      |> Decimal.mult(trading_symbol.base_asset_increment)

    received_qty =
      Decimal.mult(order_qty, price)
      |> Decimal.div_int(trading_symbol.quote_asset_increment)
      |> Decimal.mult(trading_symbol.quote_asset_increment)

    {order_qty, received_qty}
  end
end
