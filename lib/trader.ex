defmodule Trader do
  @moduledoc """
  Process for executing trades.

  Traders get planned execution and execute them.
  """

  alias Trader.Impl
  alias Types.PlannedExecution

  @doc """
  Execute planned execution
  """
  @spec execute(PlannedExecution.t()) :: :ok
  def execute(planned_execution) do
    Impl.execute(planned_execution)
  end
end
