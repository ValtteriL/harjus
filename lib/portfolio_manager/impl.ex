defmodule PortfolioManager.Impl do
  @moduledoc """
  Implementation for PortfolioManager
  """

  require Logger
  alias PortfolioManager.Args
  alias PortfolioManager.TradingFeeCalculator
  alias Types.Opportunity

  @spec new(args :: Args.t()) :: Args.t()
  def new(args), do: args

  @spec filter_opportunities(state :: Args.t(), opportunities :: [Opportunity.t()]) :: [
          Opportunity.t()
        ]
  def filter_opportunities(state, opportunities) do
    profitable_opportunities =
      opportunities
      |> Enum.filter(fn x ->
        # filter unprofitable, too low capacity opportunities

        commission =
          TradingFeeCalculator.total_commission_percentage(
            x.path,
            state.commission
          )

        x.profit - commission >= state.min_profit_percentage &&
          x.capacity >= state.min_capacity
      end)
      # sort by profit * capacity in relative asset value
      |> Enum.sort(fn %{path: [firstsymbol1 | _], profit: profit1, capacity: cap1},
                      %{path: [firstsymbol2 | _], profit: profit2, capacity: cap2} ->
        value1 = Map.get(state.relative_asset_values, firstsymbol1.quote_asset, 0.0)
        value2 = Map.get(state.relative_asset_values, firstsymbol2.quote_asset, 0.0)

        value2 * profit2 * cap2 < value1 * profit1 * cap1
      end)

    profitable_opportunities
  end
end
