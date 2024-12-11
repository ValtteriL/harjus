defmodule Arbmapper do
  @moduledoc """
  Module for finding arbitrage opportunities.
  """

  @doc """
  Generate trading paths and symbols to subscribe to from symbols

  Returns trading symbols to buy that make up a cycle

  starting_paths can be provided to limit to cycles that start and end at those symbols
  This also limits the symbols to subscribe to to those in the paths
  """
  @spec generate_trading_paths(
          symbols :: [
            %{symbol: charlist(), baseAsset: charlist(), quoteAsset: charlist()}
          ],
          starting_symbols :: [charlist()]
        ) :: {trading_paths :: [[:digraph.label()]], symbol_list :: [charlist()]}
  def generate_trading_paths(symbols, starting_symbols \\ []) do
    graph = generate_graph(symbols)

    full_edges = :digraph.edges(graph) |> Enum.map(fn e -> :digraph.edge(graph, e) end)

    :digraph.vertices(graph)
    |> Enum.map(fn x -> get_simple_cycles_for_vertex(graph, x) end)
    |> Enum.concat()
    |> Enum.map(fn x -> vertex_path_to_symbols(full_edges, x) end)
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
    for s <- symbols do
      :digraph.add_edge(graph, s[:baseAsset], s[:quoteAsset], s[:symbol])
    end

    graph
  end

  # get list of simple cycles for vertex
  @spec get_simple_cycles_for_vertex(graph :: :digraph.graph(), vertex :: :digraph.vertex()) :: [
          [:digraph.vertex()]
        ]
  defp get_simple_cycles_for_vertex(graph, vertex) do
    neighbors =
      :digraph.out_neighbours(graph, vertex)
      |> Enum.map(fn x -> {x, [vertex]} end)

    dfs(graph, vertex, neighbors)
    |> List.flatten()
    |> Enum.chunk_while([], &chunk_fun/2, &after_fun/1)
  end

  @spec dfs(
          graph :: :digraph.graph(),
          start :: :digraph.vertex(),
          neighbors :: [{:digraph.vertex(), [:digraph.vertex()]}],
          cycles :: [
            :digraph.vertex()
          ]
        ) :: [[:digraph.vertex()]]
  defp dfs(graph, start, neighbors, cycles \\ [])

  defp dfs(_graph, _start, [], cycles) do
    cycles
  end

  defp dfs(graph, start, [{start, acc} | tail], cycles) do
    dfs(graph, start, tail, [start | acc] ++ cycles)
  end

  defp dfs(graph, start, [{current, acc} | tail], cycles) do
    cond do
      length(acc) > 4 ->
        dfs(graph, start, tail, cycles)

      current in acc ->
        dfs(graph, start, tail, cycles)

      true ->
        new_acc = [current | acc]
        neighbors = :digraph.out_neighbours(graph, current) |> Enum.map(fn x -> {x, new_acc} end)
        dfs(graph, start, neighbors ++ tail, cycles)
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
