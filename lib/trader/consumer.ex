defmodule Trader.Consumer do
  @moduledoc """
  ConsumerSupervisor for Trader
  """

  use ConsumerSupervisor

  alias Trader.Impl
  alias Types.Opportunity

  @impl ConsumerSupervisor
  def init(max_number_workers) do
    children = [%{id: Impl, start: {__MODULE__, :handle_event, []}, restart: :temporary}]

    opts = [
      strategy: :one_for_one,
      subscribe_to: [{PortfolioManager, max_demand: max_number_workers}]
    ]

    ConsumerSupervisor.init(children, opts)
  end

  @spec handle_event(Opportunity.t()) :: {:ok, pid()}
  def handle_event(opportunity) do
    Task.start_link(fn ->
      Impl.execute_opportunity(opportunity)
    end)
  end
end
