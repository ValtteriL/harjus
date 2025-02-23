defmodule OpportunityWatcher.Impl do
  @moduledoc """
  Opportunity watcher implementation.
  """

  require Logger
  alias OpportunityWatcher.Args
  alias OpportunityWatcher.Opportunity
  alias OpportunityWatcher.State
  alias Types.PriceUpdate

  @spec new(args :: Args.t()) :: State.t()
  def new(%Args{
        trading_paths: trading_paths,
        min_capacity: min_capacity,
        min_profit_percentage: min_profit_percentage,
        commission: commission
      }) do
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
      |> Enum.map(fn x -> {x, {Decimal.new(1), Decimal.new(0)}} end)
      |> Map.new()

    # initialize symbol to trading symbol map
    symbol_to_trading_symbol_map =
      trading_paths
      |> List.flatten()
      |> Enum.uniq()
      |> Enum.group_by(fn x -> x.symbol end)
      |> Map.new(fn {symbol, list} ->
        {symbol,
         Enum.map(list, fn x ->
           {x.position, x}
         end)
         |> Enum.into(%{})}
      end)

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

    %State{
      pathid_to_path_map: pathid_to_path_map,
      trading_symbol_to_price_qty_tuple: trading_symbol_to_price_qty_tuple,
      symbol_to_pathids_map: symbol_to_pathids_map,
      pathid_to_profit_cap_tuple: pathid_to_profit_cap_tuple,
      symbol_to_trading_symbol_map: symbol_to_trading_symbol_map,
      min_capacity: min_capacity,
      min_profit_percentage: min_profit_percentage,
      commission: commission
    }
  end

  @spec price_update(state :: State.t(), update :: PriceUpdate.t()) ::
          {State.t(), [Types.Opportunity.t()]}
  def price_update(state = %State{}, %{
        symbol: symbol,
        ask_price: ask_price,
        ask_qty: ask_qty,
        bid_price: bid_price,
        bid_qty: bid_qty
      }) do
    # update price and quantity on long + short
    new_trading_symbol_to_price_qty_tuple =
      state.trading_symbol_to_price_qty_tuple
      |> Map.replace_lazy(
        Map.get(state.symbol_to_trading_symbol_map[symbol], :long),
        fn _ -> {ask_price, ask_qty} end
      )
      |> Map.replace_lazy(Map.get(state.symbol_to_trading_symbol_map[symbol], :short), fn _ ->
        {
          Decimal.div(1, bid_price),
          Decimal.mult(bid_qty, bid_price)
        }
      end)

    # recalculate profit and capacity for affected paths
    affected_pathids = state.symbol_to_pathids_map[symbol]

    new_pathid_profit_cap =
      Enum.map(affected_pathids, fn pathid ->
        path = state.pathid_to_path_map[pathid]
        profit = Opportunity.profit(path, new_trading_symbol_to_price_qty_tuple, state.commission)

        capacity =
          Opportunity.capacity(
            path,
            new_trading_symbol_to_price_qty_tuple
          )

        {pathid, {profit, capacity}}
      end)

    # replace profit and capacity for affected paths
    new_pathid_to_profit_cap_tuple =
      Enum.reduce(new_pathid_profit_cap, state.pathid_to_profit_cap_tuple, fn {pathid, profit_cap},
                                                                              acc ->
        Map.replace!(acc, pathid, profit_cap)
      end)

    # update state
    new_state = %State{
      pathid_to_path_map: state.pathid_to_path_map,
      symbol_to_pathids_map: state.symbol_to_pathids_map,
      trading_symbol_to_price_qty_tuple: new_trading_symbol_to_price_qty_tuple,
      pathid_to_profit_cap_tuple: new_pathid_to_profit_cap_tuple,
      symbol_to_trading_symbol_map: state.symbol_to_trading_symbol_map,
      min_capacity: state.min_capacity,
      min_profit_percentage: state.min_profit_percentage,
      commission: state.commission
    }

    # get newly appeared opportunities
    new_opportunities =
      new_pathid_profit_cap
      # filter nonprofitable, insufficient capacity
      |> Enum.filter(fn {_, {profit, capacity}} ->
        Decimal.gt?(profit, state.min_profit_percentage) and
          Decimal.gt?(capacity, state.min_capacity)
      end)
      |> Enum.map(fn {pathid, {profit, capacity}} ->
        path = state.pathid_to_path_map[pathid]
        %Types.Opportunity{path: path, profit: profit, capacity: capacity}
      end)

    {new_state, new_opportunities}
  end
end
