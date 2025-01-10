defmodule Executor.Impl do
  @moduledoc """
  Implementation for executor
  """

  @type opportunity() :: Executor.opportunity()

  require Logger

  @doc """
  Create initial state
  """
  def new(_arg) do
    %{}
  end

  @doc """
  Execute opportunity
  """
  @spec execute_opportunity(state :: any(), opportunity :: opportunity()) :: :ok
  def execute_opportunity(state, opportunity) do
    Logger.debug("Received opportunity: #{inspect(opportunity)}")
    state
  end

  @doc """
  Act on execution report
  """
  @spec send_execution_report(state :: any(), execution_report :: any()) :: :ok
  def send_execution_report(state, execution_report) do
    Logger.debug("Received execution report: #{inspect(execution_report)}")
    state
  end
end
