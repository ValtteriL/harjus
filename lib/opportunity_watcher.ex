defmodule OpportunityWatcher do
  @moduledoc """
  Process for watching for arbitrage opportunities.

  Gets trading symbol price and quantity updates, and emits arbitrage opportunities.
  Arbitrage opportunity = positive return on a cycle
  """

  use GenServer

  @type update() ::
          {symbol :: charlist(), ask_price :: float(), ask_qty :: float(), bid_price :: float(),
           bid_qty :: float()}
  @type trading_path() :: [TradingSymbol.t()]
  @type price_qty_tuple() :: {price :: float(), quantity :: float()}
  @type profit_cap_tuple() :: {profit :: float(), capacity :: float()}
  @type state() :: %{
          pathid_to_path_map: %{integer() => trading_path()},
          trading_symbol_to_price_qty_tuple: %{TradingSymbol.t() => price_qty_tuple()},
          symbol_to_pathids_map: %{charlist() => [integer()]},
          pathid_to_profit_cap_tuple: %{integer() => profit_cap_tuple()}
        }

  # API

  @doc """
  Start the opportunity watcher

  Args:
    trading_paths: list of trading symbol lists to watch for arbitrage opportunities
  """
  @spec start_link(trading_paths :: [trading_path()]) ::
          :ignore | {:error, any()} | {:ok, pid()}
  def start_link(trading_paths) do
    GenServer.start_link(__MODULE__, trading_paths, name: __MODULE__)
  end

  @doc """
  Update trading symbol price and quantity

  This triggers a recalculation of arbitrage opportunities
  """
  @spec update_symbol(update :: update()) :: :ok
  def update_symbol(update) do
    GenServer.cast(__MODULE__, {:update_symbol, update})
  end

  # Callbacks

  @impl true
  @spec init(trading_paths :: [trading_path()]) ::
          {:ok, state()}
  def init(trading_paths) do
    # initialize pathid to path map
    pathid_to_path_map =
      trading_paths
      |> Enum.with_index()
      |> Enum.map(fn {path, index} -> {index, path} end)
      |> Map.new()

    # initialize current prices and quantities for each trading symbol
    trading_symbol_to_price_qty_tuple =
      trading_paths
      |> List.flatten()
      |> Enum.uniq()
      |> Enum.map(fn x -> {x, {1.0, 0.0}} end)
      |> Map.new()

    # initialize symbol to pathids map
    symbol_to_pathids_map =
      trading_paths
      |> Enum.with_index()
      |> Enum.flat_map(fn {path, index} ->
        Enum.map(path, fn trading_symbol -> {trading_symbol, index} end)
      end)
      |> Enum.group_by(fn {x, _} -> x.symbol end)
      |> Enum.map(fn {symbol, list} ->
        {symbol, Enum.map(list, fn {_, index} -> index end) |> Enum.uniq()}
      end)
      |> Map.new()

    # initialize pathid to profit cap tuple
    pathid_to_profit_cap_tuple =
      trading_paths
      |> Enum.with_index()
      |> Enum.map(fn {_path, index} ->
        {index, {0.0, 0.0}}
      end)
      |> Map.new()

    initial_state = %{
      pathid_to_path_map: pathid_to_path_map,
      trading_symbol_to_price_qty_tuple: trading_symbol_to_price_qty_tuple,
      symbol_to_pathids_map: symbol_to_pathids_map,
      pathid_to_profit_cap_tuple: pathid_to_profit_cap_tuple
    }

    {:ok, initial_state}
  end

  @impl true
  @spec handle_cast(
          {:update_symbol, update :: update()},
          state()
        ) ::
          {:noreply, state()}
  def handle_cast({:update_symbol, {symbol, ask_price, ask_qty, bid_price, bid_qty}}, state) do
    # update price and quantity on long + short
    new_trading_symbol_to_price_qty_tuple =
      state.trading_symbol_to_price_qty_tuple
      |> Map.replace(%TradingSymbol{symbol: symbol, position: :long}, {ask_price, ask_qty})
      |> Map.replace(%TradingSymbol{symbol: symbol, position: :short}, {
        bid_price ** -1,
        bid_qty * bid_price
      })

    # recalculate profit and capacity for affected paths
    affected_pathids = state.symbol_to_pathids_map[symbol]

    new_pathid_profit_cap =
      affected_pathids
      |> Enum.map(fn pathid ->
        path = state.pathid_to_path_map[pathid]
        profit = Opportunity.profit(path, new_trading_symbol_to_price_qty_tuple)
        capacity = Opportunity.capacity(path, new_trading_symbol_to_price_qty_tuple, profit)
        {pathid, {profit, capacity}}
      end)

    # replace profit and capacity for affected paths
    new_pathid_to_profit_cap_tuple =
      Enum.reduce(new_pathid_profit_cap, state.pathid_to_profit_cap_tuple, fn {pathid, profit_cap},
                                                                              acc ->
        Map.replace!(acc, pathid, profit_cap)
      end)

    # update state
    new_state = %{
      pathid_to_path_map: state.pathid_to_path_map,
      symbol_to_pathids_map: state.symbol_to_pathids_map,
      trading_symbol_to_price_qty_tuple: new_trading_symbol_to_price_qty_tuple,
      pathid_to_profit_cap_tuple: new_pathid_to_profit_cap_tuple
    }

    # calculate arbitrage opportunities
    opportunities =
      new_pathid_to_profit_cap_tuple
      # filter nonprofitable, insufficient capacity
      |> Enum.filter(fn {_, {profit, capacity}} -> profit > 0.0 and capacity > 0.0 end)
      |> Enum.map(fn {pathid, {profit, capacity}} ->
        path = state.pathid_to_path_map[pathid]
        {path, profit, capacity}
      end)

    # send any opportunities to Portfolio Manager
    if length(opportunities) > 0 do
      PortfolioManager.send_opportunities(opportunities)
    end

    {:noreply, new_state}
  end
end
