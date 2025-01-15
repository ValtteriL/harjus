defmodule Trader.Server do
  @moduledoc """
  Process for executing trades.

  Gets approved and prioritized opportunities from PortfolioManager,
  and executes them.

  While executing a trade, discards all new opportunities.
  """

  # maybe statem more appropriate?
  use GenServer
  require Logger

  @type opportunity() :: Trader.opportunity()

  alias Trader.Impl

  @impl GenServer
  @spec init(any()) :: {:ok, %{}}
  def init(state) do
    {:ok, state}
  end

  @impl GenServer
  @spec handle_cast({:execute_opportunity, opportunity()}, state :: any()) :: {:noreply, any()}
  def handle_cast({:execute_opportunity, opportunity}, state) do
    {:noreply, Impl.execute_opportunity(state, opportunity)}
  end
end
