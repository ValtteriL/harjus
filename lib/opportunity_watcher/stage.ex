defmodule OpportunityWatcher.Stage do
  @moduledoc """
  Process for watching for arbitrage opportunities.

  Gets trading symbol price and quantity updates, and emits arbitrage opportunities.
  Arbitrage opportunity = positive return on a cycle
  """

  use GenStage

  alias OpportunityWatcher.Impl
  alias OpportunityWatcher.State
  alias Types.Opportunity

  @type update() :: OpportunityWatcher.update()

  @impl GenStage
  # Buffer of one - MOST events discarded if no demand available
  def init(state), do: {:producer, state, [buffer_size: 1]}

  @impl GenStage
  def handle_demand(_demand, state) do
    # We don't care about the demand
    {:noreply, [], state}
  end

  @impl GenStage
  @spec handle_cast({:price_update, update :: update()}, state :: State.t()) ::
          {:noreply, [Opportunity.t()], State.t()}
  def handle_cast({:price_update, update}, state) do
    # Dispatch immediately
    new_state = Impl.price_update(state, update)
    opportunities = Impl.get_opportunities(new_state)
    {:noreply, opportunities, new_state}
  end

  @impl GenStage
  @spec format_discarded(discarded :: non_neg_integer(), state :: term()) :: boolean()
  def format_discarded(_discarded, _state) do
    # silence logging of discarded events
    false
  end
end
