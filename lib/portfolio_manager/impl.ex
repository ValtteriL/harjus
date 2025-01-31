defmodule PortfolioManager.Impl do
  @moduledoc """
  Implementation for PortfolioManager
  """

  require Logger
  alias PortfolioManager.Args
  alias Types.Opportunity
  alias PortfolioManager.Balance

  @spec new(args :: Args.t()) :: Args.t()
  def new(args = %Args{}), do: args

  @spec filter_opportunities(state :: Args.t(), opportunities :: [Opportunity.t()]) :: [
          Opportunity.t()
        ]
  def filter_opportunities(state = %Args{}, opportunities = [%Opportunity{} | _]) do
    filtered_opportunities =
      opportunities
      # sort by profit * capacity in relative asset value
      |> Enum.sort(fn %{path: [firstsymbol1 | _], profit: profit1, capacity: cap1},
                      %{path: [firstsymbol2 | _], profit: profit2, capacity: cap2} ->
        value1 = Map.get(state.relative_asset_values, firstsymbol1.quote_asset, Decimal.new(0))
        value2 = Map.get(state.relative_asset_values, firstsymbol2.quote_asset, Decimal.new(0))

        balance1 = Balance.get(firstsymbol1.quote_asset)
        balance2 = Balance.get(firstsymbol2.quote_asset)

        Decimal.lt?(
          Decimal.mult(Decimal.mult(value2, profit2), Decimal.min(cap2, balance2)),
          Decimal.mult(Decimal.mult(value1, profit1), Decimal.min(cap1, balance1))
        )
      end)
      # take only the best (all others will have overlapping pairs and can be ignored)
      |> Enum.take(1)

    Logger.debug("Filtered opportunities: #{inspect(filtered_opportunities)}")

    filtered_opportunities
  end
end
