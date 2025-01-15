defmodule Trader.Impl do
  @moduledoc """
  Implementation for trader
  """

  alias Types.Opportunity
  require Logger

  @doc """
  Create initial state
  """
  def new(_arg) do
    :does_not_matter
  end

  @doc """
  Execute opportunity
  """
  @spec execute_opportunity(opportunity :: Opportunity.t()) :: :ok
  def execute_opportunity(opportunity) do
    Logger.debug(opportunity)
    :ok
  end
end
