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
    trading_paths: list of trading symbol lists to watch for arbitrage opportunities
  """
  @spec start_link([[charlist()]]) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(trading_paths) do
    GenServer.start_link(__MODULE__, trading_paths)
  end

  @doc """
  Update trading symbol price and quantity

  This triggers a recalculation of arbitrage opportunities
  """
  @spec update_symbol(pid, {charlist(), float(), float()}) :: :ok
  def update_symbol(pid, update) do
    GenServer.cast(pid, {:update_symbol, update})
  end

  # Callbacks

  @impl true
  @spec init([[charlist()]]) ::
          {:ok,
           %{
             trading_paths: [[charlist()]],
             current_prices_quantities: %{
               charlist() => %{best_ask: float(), quantity: float()}
             }
           }}
  def init(trading_paths) do
    # initialize current prices and quantities for each trading symbol
    current_prices_quantities =
      trading_paths
      |> List.flatten()
      |> Enum.uniq()
      |> Enum.map(fn x -> {x, %{:best_ask => 0.0, :quantity => 0.0}} end)
      |> Map.new()

    initial_state = %{
      trading_paths: trading_paths,
      current_prices_quantities: current_prices_quantities
    }

    {:ok, initial_state}
  end

  @impl true
  @spec handle_cast({:update_symbol, {charlist(), float(), float()}}, %{
          trading_paths: [[charlist()]],
          current_prices_quantities: %{charlist() => %{best_ask: float(), quantity: float()}}
        }) ::
          {:noreply,
           %{
             trading_paths: [[charlist()]],
             current_prices_quantities: %{
               charlist() => %{best_ask: float(), quantity: float()}
             }
           }}
  def handle_cast({:update_symbol, {symbol, best_ask, quantity}}, state) do
    # update state
    new_state = %{
      trading_paths: state.trading_paths,
      current_prices_quantities:
        state.current_prices_quantities
        |> Map.replace(symbol, %{best_ask: best_ask, quantity: quantity})
    }

    # calculate arbitrage opportunities and emit
    opportunities =
      new_state.trading_paths
      |> Enum.map(fn path ->
        {path, Opportunity.profit(path, new_state.current_prices_quantities)}
      end)
      |> Enum.filter(fn {_, profit} -> profit > 0.0 end) # filter nonprofitable
      |> Enum.map(fn {path, profit} ->
        capacity = Opportunity.capacity(path, new_state.current_prices_quantities, profit)
        {path, profit, capacity}
      end)

    IO.puts("Opportunities: #{inspect(opportunities)}")
    # TODO: emit

    {:noreply, new_state}
  end
end
