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
  alias Types.PriceUpdate

  @impl GenStage
  # Buffer of one - MOST events discarded if no demand available
  def init(state),
    do: {:producer_consumer, state, subscribe_to: [{PriceStreamer}]}

  @impl GenStage
  # silence logging of discarded events
  def format_discarded(_discarded, _state), do: false

  @impl GenStage
  @spec handle_events(updates :: [PriceUpdate.t()], _from :: any(), state :: State.t()) ::
          {:noreply, [Opportunity.t()], State.t()}
  def handle_events(updates, _from, state) do
    # Dispatch newly appeared opportunities immediately
    {new_state, new_opportunities} =
      updates
      |> Enum.reduce({state, []}, fn update, {state, _opportunities} ->
        Impl.price_update(state, update)
      end)

    {:noreply, new_opportunities, new_state}
  end
end
