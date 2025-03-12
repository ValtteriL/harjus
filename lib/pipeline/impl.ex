defmodule Pipeline.Impl do
  @moduledoc """
  Implementation of the pipeline
  """

  alias Pipeline.ExecutionPlanner
  alias Pipeline.PricingTable
  alias Types.TradingSymbol

  @spec new(
          trading_paths :: [TradingSymbol.t()],
          commission_percentage :: Decimal.t(),
          relative_asset_values :: any()
        ) :: any()
  def new(trading_paths, commission_percentage, relative_asset_values) do
    Decimal.Context.set(%Decimal.Context{Decimal.Context.get() | precision: 16})

    %{
      pricing_table: PricingTable.new(trading_paths),
      commission_percentage: commission_percentage,
      relative_asset_values: relative_asset_values
    }
  end

  @spec price_update(state :: any(), update :: tuple()) :: any()
  def price_update(
        state = %{
          pricing_table: pricing_table,
          commission_percentage: commission_percentage,
          relative_asset_values: relative_asset_values
        },
        update = {_symbol, _ask_price, _ask_qty, _bid_price, _bid_qty}
      ) do
    Metrics.report_price_update()

    # update prices, get affected pahts
    {new_pricing_table, affected_paths} = PricingTable.update_get_affected(pricing_table, update)

    # get balances, reserved symbols
    balances = Balance.get_balances()
    reserved_symbols = ReservedSymbols.get_reserved()

    affected_paths
    |> Enum.reject(fn path ->
      # reject unsuitable paths
      first_symbol = path |> List.first()

      starting_currency_balance =
        Map.get(balances, starting_currency(first_symbol), Decimal.new(0))

      # not enough balance
      # reserved symbols
      # price lte 0
      Decimal.lt?(starting_currency_balance, min_qty(first_symbol)) ||
        path |> Enum.any?(fn ts -> Enum.member?(reserved_symbols, {ts.symbol, ts.position}) end) ||
        path |> Enum.any?(fn ts -> Decimal.lte?(ts.price, 0) end)
    end)
    |> Enum.map(fn path ->
      # plan execution for each affected path

      starting_currency = path |> List.first() |> starting_currency()

      ExecutionPlanner.plan_execution(
        path,
        balances[starting_currency],
        commission_percentage,
        relative_asset_values
      )
    end)
    # sort by total profit
    |> Enum.sort_by(fn planned_execution -> planned_execution.total_profit end, :desc)
    # take top 2 with different starting currencies and no overlapping tradingsymbols
    # consider only those with positive total profit
    |> Enum.reduce_while([], fn plan, acc ->
      cond do
        Decimal.lte?(plan.total_profit, 0) ->
          {:halt, acc}

        Enum.empty?(acc) ->
          {:cont, [plan]}

        length(acc) == 1 and no_overlapping_symbols(plan, List.first(acc)) ->
          {:halt, [plan | acc]}

        true ->
          {:cont, acc}
      end
    end)
    # reserve symbols, balance & dispatch trades
    |> Enum.each(fn planned_execution ->
      planned_execution.trades |> ReservedSymbols.reserve_list!()

      first_symbol = planned_execution.trades |> List.first()
      Balance.reserve!(starting_currency(first_symbol), starting_qty(first_symbol))

      # dispatch trades
      Task.Supervisor.start_child(
        TraderSupervisor,
        fn ->
          # trap exits to allow for finishing trades on exit
          Process.flag(:trap_exit, true)

          delta = Trader.execute(planned_execution)

          # release symbols, balance
          Balance.release(delta)
          planned_execution.trades |> ReservedSymbols.release_list!()
        end,
        # never restart
        restart: :transient,
        max_restarts: 0
      )
    end)

    %{state | pricing_table: new_pricing_table}
  end

  defp starting_currency(ts = %TradingSymbol{position: :long}), do: ts.quote_asset
  defp starting_currency(ts = %TradingSymbol{position: :short}), do: ts.base_asset
  defp starting_qty(ts = %TradingSymbol{position: :long}), do: Decimal.mult(ts.qty, ts.price)
  defp starting_qty(ts = %TradingSymbol{position: :short}), do: ts.qty

  defp min_qty(ts = %TradingSymbol{position: :long}), do: ts.min_notional
  defp min_qty(ts = %TradingSymbol{position: :short}), do: Decimal.mult(ts.min_notional, ts.price)

  # symbol and position must be different
  defp no_overlapping_symbols(planned_execution1, planned_execution2) do
    Enum.all?(planned_execution1.trades, fn ts1 ->
      Enum.all?(planned_execution2.trades, fn ts2 ->
        {ts1.symbol, ts1.position} != {ts2.symbol, ts2.position}
      end)
    end)
  end
end
