defmodule PortfolioManager do
  @moduledoc """
  Process for filtering, and prioritizing opportunities.

  Gets opportunities from the OpportunityWatcher,
  filters out unprofitable ones,
  and sends the most profitable to Executor, if any.
  """

  use GenServer
  require Logger

  @type pm_args() :: %{
          min_profit_percentage: float(),
          min_profit_capacity: float(),
          standard_commission: float(),
          tax_commission: float(),
          discount: float()
        }
  @type state() :: %{
          # executor pid
          pid: pid(),
          min_profit_percentage: float(),
          min_profit_capacity: float(),
          standard_commission: float(),
          tax_commission: float(),
          discount: float()
        }

  @type trading_symbol() :: {charlist(), :long | :short}
  @type opportunity() :: {path :: [trading_symbol()], profit :: float(), capacity :: float()}

  # API

  @doc """
  Start the portfolio manager

  Args:
    min_profit_percentage : minimum profit percentage to consider an opportunity
    min_profit_capacity : minimum capacity to consider an opportunity
    standard_commission : standard trading commission
    tax_commission : trading tax commission
    discount : discount rate on standard commission if paying fees with BNB
  """
  @spec start_link(args :: pm_args()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
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
  @spec init(args :: pm_args()) ::
          {:ok, state()}
  def init(args) do
    pid = Process.whereis(Executor)

    initial_state = %{
      pid: pid,
      min_profit_percentage: args.min_profit_percentage,
      min_profit_capacity: args.min_profit_capacity,
      standard_commission: args.standard_commission,
      tax_commission: args.tax_commission,
      discount: args.discount
    }

    {:ok, initial_state}
  end

  @impl true
  @spec handle_cast(
          {:update_opportunities, [opportunity()]},
          state()
        ) ::
          {:noreply, state()}
  def handle_cast(
        {:update_opportunities, opportunities},
        state
      ) do
    # TODO
    Logger.notice("Portfolio Manager: received opportunities #{inspect(opportunities)}")

    {:noreply, state}
  end
end
