defmodule OpportunityWatcher do
  @moduledoc """
  Process for watching for arbitrage opportunities.

  Gets trading symbol price and quantity updates, and emits arbitrage opportunities.
  Arbitrage opportunity = positive return on a cycle
  """

  use GenServer

  # API

  @doc """
  Start the opportunity watcher

  Args:
    pid: pid of the process to send opportunity messages
    trading_paths: list of trading symbol lists to watch for arbitrage opportunities
  """
  @spec start_link(trading_paths :: [[charlist()]]) ::
          :ignore | {:error, any()} | {:ok, pid()}
  def start_link(trading_paths) do
    GenServer.start_link(__MODULE__, trading_paths, name: __MODULE__)
  end

  @doc """
  Update trading symbol price and quantity

  This triggers a recalculation of arbitrage opportunities
  """
  @spec update_symbol(pid :: pid(), update :: {charlist(), float(), float()}) :: :ok
  def update_symbol(pid, update) do
    GenServer.cast(pid, {:update_symbol, update})
  end

  # Callbacks

  @impl true
  @spec init(trading_paths :: [[charlist()]]) ::
          {:ok,
           %{
             pid: pid(),
             trading_paths: [[charlist()]],
             current_prices_quantities: %{
               charlist() => %{best_ask: float(), quantity: float()}
             }
           }}
  def init(trading_paths) do
    pid = Process.whereis(PortfolioManager)

    # initialize current prices and quantities for each trading symbol
    current_prices_quantities =
      trading_paths
      |> List.flatten()
      |> Enum.uniq()
      |> Enum.map(fn x -> {x, %{:best_ask => 1.0, :quantity => 0.0}} end)
      |> Map.new()

    initial_state = %{
      pid: pid,
      trading_paths: trading_paths,
      current_prices_quantities: current_prices_quantities
    }

    {:ok, initial_state}
  end

  @impl true
  @spec handle_cast(
          {:update_symbol, {symbol :: charlist(), best_ask :: float(), quantity :: float()}},
          %{
            pid: pid(),
            trading_paths: [[charlist()]],
            current_prices_quantities: %{charlist() => %{best_ask: float(), quantity: float()}}
          }
        ) ::
          {:noreply,
           %{
             pid: pid(),
             trading_paths: [[charlist()]],
             current_prices_quantities: %{
               charlist() => %{best_ask: float(), quantity: float()}
             }
           }}
  def handle_cast({:update_symbol, {symbol, best_ask, quantity}}, state) do
    # update state
    new_state = %{
      pid: state.pid,
      trading_paths: state.trading_paths,
      current_prices_quantities:
        state.current_prices_quantities
        |> Map.replace(symbol, %{best_ask: best_ask, quantity: quantity})
    }

    # calculate arbitrage opportunities
    opportunities =
      new_state.trading_paths
      |> Enum.map(fn path ->
        {path, Opportunity.profit(path, new_state.current_prices_quantities)}
      end)
      # filter nonprofitable
      |> Enum.filter(fn {_, profit} -> profit > 0.0 end)
      |> Enum.map(fn {path, profit} ->
        capacity = Opportunity.capacity(path, new_state.current_prices_quantities, profit)
        %{path: path, profit: profit, capacity: capacity}
      end)
      # filter insufficient capacity
      |> Enum.filter(fn map -> Map.fetch!(map, :capacity) > 0.0 end)

    # send any opportunities to Portfolio Manager
    if length(opportunities) > 0 do
      PortfolioManager.send_opportunities(new_state.pid, opportunities)
    end

    {:noreply, new_state}
  end
end
