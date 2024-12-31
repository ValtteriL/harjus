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
  @type state() :: %{
          pid: pid()
        }

  @type trading_symbol() :: {charlist(), :long | :short}
  @type opportunity() :: {path :: [trading_symbol()], profit :: float(), capacity :: float()}

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
          pid :: pid(),
          opportunities :: [
            opportunity()
          ]
        ) ::
          :ok
  def send_opportunities(pid, opportunities) do
    GenServer.cast(pid, {:update_opportunities, opportunities})
  end

  @doc """
  Send execution report to Executor
  """

  def send_execution_report(_pid, execution_report) do
    Logger.debug("Received execution report: #{inspect(execution_report)}")
  end

  # Callbacks

  @impl true
  @spec init({pid()}) ::
          {:ok,
           %{
             pid: pid()
           }}
  def init(pid) do
    initial_state = %{
      pid: pid
    }

    {:ok, initial_state}
  end

  @impl true
  @spec handle_cast(
          {:update_opportunities, [opportunity()]},
          %{
            pid: pid()
          }
        ) ::
          {:noreply,
           %{
             pid: pid()
           }}
  def handle_cast(
        {:update_opportunities, opportunities},
        state
      ) do
    # update state
    new_state = %{
      pid: state.pid
    }

    # TODO
    Logger.notice("Portfolio Manager: received opportunities #{inspect(opportunities)}")

    {:noreply, new_state}
  end
end
