defmodule Pipeline.Impl do
  @moduledoc """
  Implementation of the pipeline
  """

  alias Pipeline.ExecutionPlanner
  alias Pipeline.PricingTable
  alias Types.PlannedExecution
  alias Types.TradingSymbol

  @spec new(
          trading_paths :: [TradingSymbol.t()],
          commission_percentage :: Decimal.t(),
          relative_asset_values :: any()
        ) :: any()
  def new(trading_paths, commission_percentage, relative_asset_values) do
    Decimal.Context.set(%Decimal.Context{Decimal.Context.get() | precision: 16})
    %{}
  end

  @spec handle_opportunities(state :: any(), opportunities :: [PlannedExecution.t()]) :: any()
  def handle_opportunities(state, opportunities) do
    # get balances, reserved symbols
    balances = Balance.get_balances()
    reserved_symbols = ReservedSymbols.get_reserved()

    opportunities
    |> Enum.reject(fn planned_execution ->
      # reject unsuitable paths
      first_symbol = planned_execution.trades |> List.first()

      starting_currency_balance =
        Map.get(balances, starting_currency(first_symbol), Decimal.new(0))

      # balance under notional
      # reserved symbols
      Decimal.lt?(starting_currency_balance, min_qty(first_symbol)) ||
        planned_execution.trades
        |> Enum.any?(fn ts -> Enum.member?(reserved_symbols, {ts.symbol, ts.position}) end)
    end)
    # sort by total profit * balance
    |> Enum.sort_by(
      fn planned_execution ->
        Decimal.mult(
          planned_execution.total_profit,
          Map.get(balances, starting_currency_for_path(planned_execution.trades), Decimal.new(0))
        )
      end,
      &Decimal.gte?/2
    )
    # TODO: update quantities
    |> Enum.map(fn path ->
      # plan execution for each affected path

      starting_currency = path |> List.first() |> starting_currency()

      ExecutionPlanner.update_qtys(
        path,
        balances[starting_currency]
      )
    end)
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
        restart: :transient
      )
    end)

    state
  end

  defp starting_currency_for_path(path), do: path |> List.first() |> starting_currency()
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
