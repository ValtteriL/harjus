defmodule Executor.Server do
  @moduledoc """
  Process for executing trades.

  Gets approved and prioritized opportunities from PortfolioManager,
  and executes them.

  While executing a trade, discards all new opportunities.
  """

  # maybe statem more appropriate?
  use GenServer
  require Logger

  @type opportunity() :: Executor.opportunity()

  alias Executor.Impl

  @impl true
  @spec init(any()) :: {:ok, %{}}
  def init(state) do
    {:ok, state}
  end

  @impl true
  @spec handle_cast({:execute_opportunity, opportunity()}, state :: any()) :: {:noreply, any()}
  def handle_cast({:execute_opportunity, opportunity}, state) do
    {:noreply, Impl.execute_opportunity(state, opportunity)}
  end

  @impl true
  @spec handle_cast({:send_execution_report, report :: any()}, state :: any()) ::
          {:noreply, any()}
  def handle_cast({:send_execution_report, report}, state) do
    {:noreply, Impl.send_execution_report(state, report)}
  end
end
