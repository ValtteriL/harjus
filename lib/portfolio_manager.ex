defmodule PortfolioManager do
  @moduledoc """
  Process for filtering, and prioritizing opportunities.

  Gets opportunities from the OpportunityWatcher,
  filters out unprofitable ones,
  and sends the most profitable to Executor, if any.
  """

  use GenServer
  require Logger

  @type trading_symbol() :: {charlist(), :long | :short}
  @type opportunity() :: {path :: [trading_symbol()], profit :: float(), capacity :: float()}

  # API

  @doc """
  Start the portfolio manager

  Args:
    pid: pid of the process to send the most profitable opportunities
    TODO: here would be place for trading fees, info which symbols are in margin, ...
  """
  @spec start_link(arg :: any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(_arg) do
    # TODO: put executor here
    pid = nil
    GenServer.start_link(__MODULE__, pid, name: __MODULE__)
  end

  @doc """
  Send opportunities to Portfolio Manager
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
