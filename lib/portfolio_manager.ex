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
    pid = nil
    {:ok, executor_pid} = Executor.start_link([])
    GenServer.start_link(__MODULE__, {pid, executor_pid}, name: __MODULE__)
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
  @spec init({pid(), pid()}) ::
          {:ok,
           %{
             pid: pid(),
             executor_pid: pid()
           }}
  def init({pid, executor_pid}) do
    initial_state = %{
      pid: pid,
      executor_pid: executor_pid
    }

    {:ok, initial_state}
  end

  @impl true
  @spec handle_cast(
          {:update_opportunities, [opportunity()]},
          %{
            pid: pid(),
            executor_pid: pid()
          }
        ) ::
          {:noreply,
           %{
             pid: pid(),
             executor_pid: pid()
           }}
  def handle_cast(
        {:update_opportunities, opportunities},
        state
      ) do
    # update state
    new_state = %{
      pid: state.pid,
      executor_pid: state.executor_pid
    }

    Logger.notice("Portfolio Manager: received opportunities #{inspect(opportunities)}")

    if length(opportunities) > 0 do
      most_profitable_opportunity = Enum.max_by(opportunities, fn {_, profit, _} -> profit end)
      GenServer.cast(state.executor_pid, {:opportunity, most_profitable_opportunity})
    end

    {:noreply, new_state}
  end
end
