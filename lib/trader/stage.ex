defmodule Trader.Stage do
  @moduledoc """
  Genstage for Trader
  """

  use GenStage

  alias Trader.Impl
  alias Types.Opportunity

  @impl GenStage
  @spec init(any()) ::
          {:consumer, any(),
           [
             {:subscribe_to,
              [
                module()
              ]}
           ]}
  def init(state),
    do: {:consumer, state, subscribe_to: [{PortfolioManager, max_demand: 1}]}

  @impl GenStage
  @spec handle_events([Opportunity.t()], any(), any()) :: {:noreply, [], any()}
  def handle_events([opportunity], _from, state) do
    Impl.execute_opportunity(opportunity)
    {:noreply, [], state}
  end
end
