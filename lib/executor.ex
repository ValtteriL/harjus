defmodule Executor do
  @moduledoc """
  Process for executing trades.

  Gets approved and prioritized opportunities from PortfolioManager,
  and executes them.

  While executing a trade, discards all new opportunities.
  """

  # maybe statem more appropriate?
  use GenServer
  require Logger

  # TODO
  @type opportunity() :: {path :: [TradingSymbol.t()], profit :: float(), capacity :: float()}

  # API

  @doc """
  Start the executor

  """
  @spec start_link(arg :: any()) ::
          :ignore | {:error, any()} | {:ok, pid()}
  def start_link(_arg) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Send opportunities to Executor
  """
  @spec send_opportunities(
          opportunities :: [
            opportunity()
          ]
        ) ::
          :ok
  def send_opportunities(opportunities) do
    GenServer.cast(__MODULE__, {:update_opportunities, opportunities})
  end

  @doc """
  Send execution report to Executor
  """

  def send_execution_report(execution_report) do
    Logger.debug("Received execution report: #{inspect(execution_report)}")
  end

  # Callbacks

  @impl true
  @spec init(any()) :: {:ok, %{}}
  def init(_args) do
    initial_state = %{}
    {:ok, initial_state}
  end

  @impl true
  @spec handle_cast({:update_opportunities, [opportunity()]}, %{}) :: {:noreply, %{}}
  def handle_cast(
        {:update_opportunities, opportunities},
        state
      ) do
    # TODO
    Logger.notice("Portfolio Manager: received opportunities #{inspect(opportunities)}")

    {:noreply, state}
  end
end
