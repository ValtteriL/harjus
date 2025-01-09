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
          min_capacity: float(),
          commission: float(),
          relative_asset_values: %{String.t() => float()}
        }
  @type state() :: pm_args()

  @type opportunity() :: {path :: [TradingSymbol.t()], profit :: float(), capacity :: float()}

  # API

  @doc """
  Start the portfolio manager

  Args:
    min_profit_percentage : minimum profit percentage to consider an opportunity
    min_capacity : minimum capacity to consider an opportunity
    commission : standard trading commission
  """
  @spec start_link(args :: pm_args()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Send opportunities to Portfolio Manager
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

  # Callbacks

  @impl true
  @spec init(args :: pm_args()) :: {:ok, state()}
  def init(args) do
    {:ok, args}
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
    profitable_opportunities =
      opportunities
      |> Enum.filter(fn {path, profit, capacity} ->
        # filter unprofitable, too low capacity opportunities

        commission =
          TradingFeeCalculator.total_commission_percentage(
            path,
            state.commission
          )

        profit - commission >= state.min_profit_percentage &&
          capacity >= state.min_capacity
      end)
      # sort by profit * capacity in relative asset value
      |> Enum.sort(fn {[firstsymbol1 | _], profit1, cap1}, {[firstsymbol2 | _], profit2, cap2} ->
        value1 = state.relative_asset_values[firstsymbol1.quote_asset]
        value2 = state.relative_asset_values[firstsymbol2.quote_asset]

        value2 * profit2 * cap2 < value1 * profit1 * cap1
      end)

    # send any profitable opportunities to Executor
    if length(profitable_opportunities) > 0 do
      Executor.send_opportunities(profitable_opportunities)
    end

    {:noreply, state}
  end
end
