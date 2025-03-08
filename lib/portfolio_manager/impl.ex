defmodule PortfolioManager.Impl do
  @moduledoc """
  Implementation for PortfolioManager
  """

  require Logger
  alias PortfolioManager.Balance
  alias Types.Opportunity

  @spec new(args :: any()) :: any()
  def new(args = %{}), do: args

  @spec filter_opportunities(state :: any(), opportunities :: [Opportunity.t()]) :: [
          Opportunity.t()
        ]
  def filter_opportunities(state = %{}, opportunities = [%Opportunity{} | _]) do
    filtered_opportunities =
      opportunities
      # sort by profit * capacity in relative asset value
      |> Enum.sort(fn %{path: [firstsymbol1 | _], profit: profit1, capacity: cap1},
                      %{path: [firstsymbol2 | _], profit: profit2, capacity: cap2} ->
        used_asset1 = get_used_asset(firstsymbol1.trading_symbol)
        used_asset2 = get_used_asset(firstsymbol2.trading_symbol)

        value1 =
          Map.get(
            state.relative_asset_values,
            used_asset1,
            Decimal.new(0)
          )

        value2 =
          Map.get(
            state.relative_asset_values,
            used_asset2,
            Decimal.new(0)
          )

        balance1 = Balance.get(used_asset1)
        balance2 = Balance.get(used_asset2)

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

  defp get_used_asset(trading_symbol) do
    case trading_symbol.position do
      :long -> trading_symbol.quote_asset
      :short -> trading_symbol.base_asset
    end
  end
end
