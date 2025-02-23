defmodule PriceStreamer.Stage do
  @moduledoc """
  Process for streaming price updates for trading symbols

  Gets trading symbol price and quantity updates, and sends them forward
  """

  use GenStage

  alias Types.Opportunity
  alias Types.PriceUpdate

  @impl GenStage
  # Buffer of one - MOST events discarded if no demand available
  def init(state), do: {:producer, state, [buffer_size: 1]}

  @impl GenStage
  # We don't care about the demand
  def handle_demand(_demand, state), do: {:noreply, [], state}

  @impl GenStage
  @spec handle_cast({:price_update, update :: PriceUpdate.t()}, state :: any()) ::
          {:noreply, [Opportunity.t()], any()}
  def handle_cast({:price_update, update}, state) do
    # Dispatch newly appeared opportunities immediately
    {:noreply, [update], state}
  end
end
