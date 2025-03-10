defmodule Pipeline.ExecutionPlanner do
  @moduledoc """
  Trade planner
  """

  alias Pipeline.ExecutionPlanner.Impl
  alias Types.PlannedExecution
  alias Types.TradingSymbol

  @doc """
  Generate execution plan for a given trading path, starting asset balance and relative asset values
  """
  @spec plan_execution([TradingSymbol.t()], Decimal.t(), Decimal.t(), map()) ::
          PlannedExecution.t()
  defdelegate plan_execution(
                path,
                starting_asset_balance,
                commission_percentage,
                relative_asset_values
              ),
              to: Impl
end
