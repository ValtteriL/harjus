defmodule Pipeline.ExecutionPlanner.Impl do
  @moduledoc """
  ExecutionPlanner implementation
  """

  alias Types.PlannedExecution
  alias Types.TradingSymbol

  require Decimal

  @spec recalculate_with_balance(PlannedExecution.t(), Decimal.t()) ::
          PlannedExecution.t()
  def recalculate_with_balance(
        %PlannedExecution{
          trades: trades = [firstsymbol = %TradingSymbol{} | _],
          total_profit: total_profit
        },
        starting_asset_balance
      ) do
    Decimal.Context.set(%Decimal.Context{Decimal.Context.get() | rounding: :down})

    max_starting_asset_qty =
      Decimal.min(
        case firstsymbol.position do
          :long -> Decimal.mult(firstsymbol.qty, firstsymbol.price)
          :short -> firstsymbol.qty
        end,
        starting_asset_balance
      )

    new_trades =
      trades
      |> Enum.map_reduce(max_starting_asset_qty, fn symbol, acc ->
        {order_qty, received_qty} = order_qty_received_qty_for_budget(acc, symbol.price, symbol)

        {
          %TradingSymbol{symbol | qty: order_qty},
          received_qty
        }
      end)
      |> elem(0)

    # new total profit simply old * (newqty/oldqty)
    # unless any of the trades have 0 qty (min_notional not met)
    new_qty = new_trades |> List.first() |> used_qty()
    old_qty = trades |> List.first() |> used_qty()

    # if any of the trades have 0 qty, return 0 profit
    new_total_profit = Decimal.mult(total_profit, Decimal.div(new_qty, old_qty))

    %PlannedExecution{
      total_profit: new_total_profit,
      trades: new_trades
    }
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

  defp used_qty(ts = %TradingSymbol{position: :long}), do: Decimal.mult(ts.qty, ts.price)
  defp used_qty(ts = %TradingSymbol{position: :short}), do: ts.qty
end
