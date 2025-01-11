defmodule PortfolioManager.Impl do
  @moduledoc """
  Process for filtering, and prioritizing opportunities.

  Gets opportunities from the OpportunityWatcher,
  filters out unprofitable ones,
  and sends the most profitable to Executor, if any.
  """

  require Logger
  alias PortfolioManager.Args
  alias PortfolioManager.TradingFeeCalculator

  @type opportunity() :: PortfolioManager.opportunity()

  @spec new(args :: Args.t()) :: Args.t()
  def new(args) do
    args
  end

  @spec opportunity_update(state :: Args.t(), opportunities :: [opportunity()]) :: Args.t()
  def opportunity_update(state, opportunities) do
    profitable_opportunities =
      opportunities
      |> Enum.filter(fn {path, profit, capacity} ->
        # filter unprofitable, too low capacity opportunities

        commission =
          TradingFeeCalculator.total_commission_percentage(
            path,
            state.commission
          )

        profit - commission >= state.min_profit_percentage &&
          capacity >= state.min_capacity
      end)
      # sort by profit * capacity in relative asset value
      |> Enum.sort(fn {[firstsymbol1 | _], profit1, cap1}, {[firstsymbol2 | _], profit2, cap2} ->
        value1 = Map.get(state.relative_asset_values, firstsymbol1.quote_asset, 0.0)
        value2 = Map.get(state.relative_asset_values, firstsymbol2.quote_asset, 0.0)

        value2 * profit2 * cap2 < value1 * profit1 * cap1
      end)

    # send best profitable opportunity to Executor
    if length(profitable_opportunities) > 0 do
      Executor.execute_opportunity(hd(profitable_opportunities))
    end

    state
  end
end
