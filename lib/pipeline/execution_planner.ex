defmodule Pipeline.ExecutionPlanner do
  @moduledoc """
  Trade planner
  """

  alias Pipeline.ExecutionPlanner.Impl
  alias Types.PlannedExecution

  @doc """
  Recalculate execution plan given starting asset balance
  """
  @spec recalculate_with_balance(PlannedExecution.t(), Decimal.t()) ::
          PlannedExecution.t()
  defdelegate recalculate_with_balance(
                planned_execution,
                starting_asset_balance
              ),
              to: Impl
end
