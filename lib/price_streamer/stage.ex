defmodule PriceStreamer.Stage do
  @moduledoc """
  Process for streaming price updates for trading symbols

  Gets trading symbol price and quantity updates, and sends them forward
  """

  use GenStage

  alias OpportunityWatcher.Impl
  alias OpportunityWatcher.State
  alias Types.Opportunity
  alias Types.PriceUpdate

  @impl GenStage
  # Buffer of one - MOST events discarded if no demand available
  def init(state), do: {:producer, state, [buffer_size: 1]}

  @impl GenStage
  # We don't care about the demand
  def handle_demand(_demand, state), do: {:noreply, [], state}

  @impl GenStage
  @spec handle_cast({:price_update, update :: PriceUpdate.t()}, state :: State.t()) ::
          {:noreply, [Opportunity.t()], State.t()}
  def handle_cast({:price_update, update}, state) do
    # Dispatch newly appeared opportunities immediately
    {new_state, opportunities} = Impl.price_update(state, update)
    {:noreply, opportunities, new_state}
  end
end
