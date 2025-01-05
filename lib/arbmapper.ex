defmodule Arbmapper do
  @moduledoc """
  Module for finding arbitrage opportunities.
  """

  @doc """
  Generate trading paths and symbols to subscribe to from symbols

  Returns trading symbols to buy that make up a cycle

  Does not return trading paths of depth 1, as they are not useful for arbitrage

  starting_paths can be provided to limit to cycles that start and end at those symbols
  This also limits the symbols to subscribe to to those in the paths
  """
  @spec generate_trading_paths(
          symbols :: [
            %{symbol: charlist(), baseAsset: charlist(), quoteAsset: charlist()}
          ],
          opts :: [
            starting_symbols: [charlist()],
            depth: integer()
          ]
        ) ::
          {trading_paths :: [[TradingSymbol.t()]], symbol_list :: [charlist()]}
  def generate_trading_paths(symbols, opts \\ []) do
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
  @spec generate_graph(
          symbols :: [%{symbol: charlist(), baseAsset: charlist(), quoteAsset: charlist()}]
        ) ::
          :digraph.graph()
  defp generate_graph(symbols) do
    graph = :digraph.new()

    # Add symbols as vertices
    uniq_base_symbols = symbols |> Enum.map(fn x -> x[:baseAsset] end) |> Enum.uniq()

    for s <- uniq_base_symbols do
      :digraph.add_vertex(graph, s)
    end

    # Add trading pairs as edges
    # forward (long), backward (short)
    for s <- symbols do
      :digraph.add_edge(graph, s[:baseAsset], s[:quoteAsset], %TradingSymbol{
        symbol: s[:symbol],
        position: :long
      })

      :digraph.add_edge(graph, s[:quoteAsset], s[:baseAsset], %TradingSymbol{
        symbol: s[:symbol],
        position: :short
      })
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
end
