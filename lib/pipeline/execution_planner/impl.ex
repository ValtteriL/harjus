defmodule Pipeline.ExecutionPlanner.Impl do
  @moduledoc """
  ExecutionPlanner implementation
  """

  alias Types.PlannedExecution
  alias Types.TradingSymbol

  require Decimal

  @spec plan_execution([TradingSymbol.t()], Decimal.t(), Decimal.t(), map()) ::
          PlannedExecution.t()
  def plan_execution(
        path = [first_symbol = %TradingSymbol{} | _],
        starting_asset_balance,
        commission_percentage,
        relative_asset_values = %{}
      )
      when Decimal.is_decimal(starting_asset_balance) and
             Decimal.is_decimal(commission_percentage) do
    capacity = capacity(path)

    trades =
      path
      |> Enum.map_reduce(capacity, fn symbol, acc ->
        {order_qty, received_qty} = order_qty_received_qty_for_budget(acc, symbol.price, symbol)

        {
          %TradingSymbol{symbol | qty: order_qty},
          received_qty
        }
      end)
      |> elem(0)

    total_profit =
      if Decimal.eq?(capacity, 0) do
        Decimal.new(0)
      else
        # total profit = profit * capacity * relative_asset_value
        Decimal.mult(
          Decimal.mult(profit(path, commission_percentage), capacity),
          Map.fetch!(relative_asset_values, used_asset(first_symbol))
        )
      end

    %PlannedExecution{
      total_profit: total_profit,
      trades: trades
    }
  end

  defp capacity(trading_path = [firstsymbol = %TradingSymbol{} | _]) do
    qty =
      case firstsymbol.position do
        :long -> firstsymbol.qty
        :short -> Decimal.mult(firstsymbol.qty, firstsymbol.price)
      end

    Enum.reduce(trading_path, qty, fn symbol, acc ->
      quantity =
        case symbol.position do
          :long -> symbol.qty
          :short -> Decimal.mult(symbol.qty, symbol.price)
        end

      lowest = Decimal.min(Decimal.div(acc, symbol.price), quantity)

      # capacity is 0 if notional is less than min_notional
      notional = Decimal.mult(lowest, symbol.price)

      if(Decimal.lt?(notional, firstsymbol.min_notional), do: Decimal.new(0), else: lowest)
    end)
    |> Decimal.div(Decimal.add(1, profit_without_commission(trading_path)))
  end

  defp profit_without_commission(trading_path) do
    Enum.map(trading_path, fn symbol -> symbol.price end)
    |> Enum.reduce(1, fn price, acc -> Decimal.div(acc, price) end)
    |> Decimal.sub(1)
  end

  defp profit(trading_path, commission_percentage) do
    trading_path
    |> Enum.map(fn symbol -> {symbol.position, symbol.price} end)
    |> Enum.reduce(Decimal.new(1), fn {position, price}, acc ->
      price =
        case position do
          :long -> price
          :short -> Decimal.div(1, price)
        end

      Decimal.div(
        Decimal.mult(
          acc,
          Decimal.sub(1, commission_percentage)
        ),
        price
      )
    end)
    |> Decimal.sub(1)
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

  defp used_asset(ts = %TradingSymbol{position: :long}), do: ts.quote_asset
  defp used_asset(ts = %TradingSymbol{position: :short}), do: ts.base_asset
end
