defmodule MarketData.Arbmapper.Impl do
  @moduledoc """
  Arbmapper implementation
  """

  alias MarketData.Types.Symbol
  alias Types.TradingSymbol

  @spec generate_trading_paths(
          symbols :: [Symbol.t()],
          opts :: [
            starting_symbols: [String.t()],
            depth: integer()
          ]
        ) ::
          {trading_paths :: [[TradingSymbol.t()]], symbol_list :: [String.t()]}
  def generate_trading_paths(
        symbols = [%Symbol{} | _],
        opts \\ []
      )
      when is_list(opts) do
    starting_symbols = Keyword.get(opts, :starting_symbols, [])
    depth = Keyword.get(opts, :depth, 2)

    graph = generate_graph(symbols)

    full_edges = :digraph.edges(graph) |> Enum.map(fn e -> :digraph.edge(graph, e) end)

    trading_paths =
      :digraph.vertices(graph)
      # filter paths that don't start with starting_symbols if any defined
      |> Enum.filter(fn x -> x in starting_symbols or starting_symbols === [] end)
      |> Enum.map(fn x -> get_simple_cycles_for_vertex(graph, x, depth) end)
      |> Enum.concat()
      |> Enum.map(fn x -> vertex_path_to_symbols(full_edges, x) end)
      # filter paths with only 2 symbols (they wont happen in practice)
      |> Enum.filter(fn x -> length(x) > 2 end)

    symbol_list =
      trading_paths |> List.flatten() |> Enum.map(fn x -> x.symbol end) |> Enum.uniq()

    {trading_paths, symbol_list}
  end

  # generate graph from symbols
  @spec generate_graph(symbols :: [Symbol.t()]) ::
          :digraph.graph()
  defp generate_graph(symbols = [%Symbol{} | _]) do
    graph = :digraph.new()

    # Add symbols as vertices
    uniq_base_symbols =
      symbols |> Enum.flat_map(fn x -> [x.baseAsset, x.quoteAsset] end) |> Enum.uniq()

    for s <- uniq_base_symbols do
      :digraph.add_vertex(graph, s)
    end

    # Add trading pairs as edges
    # forward (long), backward (short)
    for s <- symbols do
      :digraph.add_edge(graph, s.baseAsset, s.quoteAsset, symbol_to_tradingsymbol(s, :long))
      :digraph.add_edge(graph, s.quoteAsset, s.baseAsset, symbol_to_tradingsymbol(s, :short))
    end

    graph
  end

  # get list of simple cycles for vertex
  @spec get_simple_cycles_for_vertex(
          graph :: :digraph.graph(),
          vertex :: :digraph.vertex(),
          depth :: integer()
        ) :: [
          [:digraph.vertex()]
        ]
  defp get_simple_cycles_for_vertex(graph, vertex, depth) do
    neighbors =
      :digraph.out_neighbours(graph, vertex)
      |> Enum.map(fn x -> {x, [vertex]} end)

    dfs(graph, vertex, neighbors, [], depth)
    |> List.flatten()
    |> Enum.chunk_while([], &chunk_fun/2, &after_fun/1)
  end

  @spec dfs(
          graph :: :digraph.graph(),
          start :: :digraph.vertex(),
          neighbors :: [{:digraph.vertex(), [:digraph.vertex()]}],
          cycles :: [
            :digraph.vertex()
          ],
          depth :: integer()
        ) :: [[:digraph.vertex()]]
  defp dfs(graph, start, neighbors, cycles, depth)

  defp dfs(_graph, _start, [], cycles, _depth) do
    cycles
  end

  defp dfs(graph, start, [{start, acc} | tail], cycles, depth) do
    dfs(graph, start, tail, [start | acc] ++ cycles, depth)
  end

  defp dfs(graph, start, [{current, acc} | tail], cycles, depth) do
    cond do
      # dont consider longer cycles than depth
      length(acc) > depth ->
        dfs(graph, start, tail, cycles, depth)

      current in acc ->
        dfs(graph, start, tail, cycles, depth)

      true ->
        new_acc = [current | acc]
        neighbors = :digraph.out_neighbours(graph, current) |> Enum.map(fn x -> {x, new_acc} end)
        dfs(graph, start, neighbors ++ tail, cycles, depth)
    end
  end

  defp chunk_fun(element, []) do
    {:cont, [element]}
  end

  defp chunk_fun(element, [h | t]) do
    if element == h do
      {:cont, [h | t] ++ [element], []}
    else
      {:cont, [h | t] ++ [element]}
    end
  end

  defp after_fun(acc) do
    {:cont, acc}
  end

  # Convert list of vertexes into list of trading pair symbols
  @spec vertex_path_to_symbols(
          edges :: [{:digraph.edge(), :digraph.vertex(), :digraph.vertex(), :digraph.label()}],
          path :: [:digraph.vertex()]
        ) :: [:digraph.label()]
  defp vertex_path_to_symbols(edges, path) do
    path
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(fn [b, q] ->
      edges
      |> Enum.filter(fn {_, from, to, _} -> to == b and from == q end)
      |> List.first()
      |> elem(3)
    end)
  end

  defp symbol_to_tradingsymbol(symbol, position) do
    %TradingSymbol{
      symbol: symbol.symbol,
      position: position,
      base_asset: symbol.baseAsset,
      quote_asset: symbol.quoteAsset,
      base_asset_increment: symbol.baseAssetIncrement,
      base_asset_precision: symbol.baseAssetPrecision,
      quote_asset_increment: symbol.quoteAssetIncrement,
      quote_asset_precision: symbol.quoteAssetPrecision,
      min_notional: symbol.minNotional
    }
  end
end
