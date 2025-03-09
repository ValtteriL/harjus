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
    |> Enum.filter(fn path ->
      # filter out affected paths for which we have not enough balance
      # filter out affected paths that contain reserved symbols

      first_symbol = path |> List.first()

      balances[starting_currency(first_symbol)] >= min_qty(first_symbol) &&
        path |> Enum.all?(fn ts -> !Enum.member?(reserved_symbols, {ts.symbol, ts.position}) end)
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
    # TODO: take top 2 with different starting currencies and no overlapping tradingsymbols
    |> Enum.to_list()
    # filter out where total profit lte 0
    |> Enum.filter(fn planned_execution ->
      Decimal.lte?(planned_execution.total_profit, Decimal.new(0))
    end)
    # reserve symbols, balance
    |> Enum.each(fn planned_execution ->
      planned_execution.trades |> ReservedSymbols.reserve_list!()

      first_symbol = planned_execution.trades |> List.first()
      # assuming symbol qty updated with the correct amount
      Balance.reserve!(starting_currency(first_symbol), first_symbol.qty)
    end)

    # TODO: dispatch trades
    |> Enum.each(fn planned_execution ->
      :ok
    end)

    %{state | pricing_table: new_pricing_table}
  end

  defp starting_currency(ts = %TradingSymbol{position: :long}), do: ts.quote_asset
  defp starting_currency(ts = %TradingSymbol{position: :short}), do: ts.base_asset

  defp min_qty(ts = %TradingSymbol{position: :long}), do: ts.min_notional
  defp min_qty(ts = %TradingSymbol{position: :short}), do: Decimal.mult(ts.min_notional, ts.price)
end
