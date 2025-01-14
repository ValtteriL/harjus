defmodule PortfolioManager.Stage do
  @moduledoc """
  Process for filtering, and prioritizing opportunities.

  Gets opportunities from the OpportunityWatcher,
  filters out unprofitable ones,
  and sends the most profitable to Executor, if any.
  """

  use GenStage

  alias PortfolioManager.Args
  alias PortfolioManager.Impl
  alias Types.Opportunity

  @impl GenStage
  @spec init(args :: Args.t()) ::
          {:producer_consumer, Args.t(),
           [
             {:buffer_size, timeout()}
             | {:subscribe_to,
                [
                  module()
                ]}
           ]}
  def init(args),
    do: {:producer_consumer, args, subscribe_to: [{OpportunityWatcher, buffer_size: 1}]}

  @impl GenStage
  @spec handle_events([event :: [Opportunity.t()]], _from :: any(), state :: Args.t()) ::
          {:noreply, [Opportunity.t()], Args.t()}
  def handle_events(events, _from, state),
    do: {:noreply, Impl.filter_opportunities(state, events), state}
end
