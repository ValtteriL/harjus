defmodule PortfolioManager.Server do
  @moduledoc """
  Process for filtering, and prioritizing opportunities.

  Gets opportunities from the OpportunityWatcher,
  filters out unprofitable ones,
  and sends the most profitable to Executor, if any.
  """

  use GenServer

  alias PortfolioManager.Args
  alias PortfolioManager.Impl

  @type opportunity() :: PortfolioManager.opportunity()

  @impl true
  @spec init(args :: Args.t()) :: {:ok, Args.t()}
  def init(args) do
    {:ok, args}
  end

  @impl true
  @spec handle_cast(
          {:opportunity_update, opportunities :: [opportunity()]},
          state :: Args.t()
        ) ::
          {:noreply, Args.t()}
  def handle_cast({:opportunity_update, opportunities}, state) do
    {:noreply, Impl.opportunity_update(state, opportunities)}
  end
end
