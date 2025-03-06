defmodule Pipeline.TradePlanner.Impl do
  @moduledoc """
  TradePlanner implementation
  """

  alias Types.PlannedExecution
  alias Types.TradingSymbol

  @spec plan_execution([TradingSymbol.t()], Decimal.t(), map()) :: PlannedExecution.t()
  def plan_execution(path, starting_asset_balance, relative_asset_values) do
    :ok
  end
end
