defmodule OpportunityWatcher.Server do
  @moduledoc """
  Process for watching for arbitrage opportunities.

  Gets trading symbol price and quantity updates, and emits arbitrage opportunities.
  Arbitrage opportunity = positive return on a cycle
  """

  use GenServer

  alias OpportunityWatcher.Impl
  alias OpportunityWatcher.State

  @type update() :: OpportunityWatcher.update()

  @impl GenServer
  def init(state) do
    {:ok, state}
  end

  @impl GenServer
  @spec handle_cast({:price_update, update :: update()}, state :: State.t()) ::
          {:noreply, State.t()}
  def handle_cast({:price_update, update}, state) do
    {:noreply, Impl.price_update(state, update)}
  end
end
