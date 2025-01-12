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
end
