defmodule Arbmapper do
  @moduledoc """
  Module for finding arbitrage opportunities.
  """

  @doc """
  Generate trading paths from symbols
  """
  @spec generate_trading_paths([
          %{symbol: charlist(), baseAsset: charlist(), quoteAsset: charlist()}
        ]) :: [[:digraph.vertex()]]
  def generate_trading_paths(symbols) do
    graph = generate_graph(symbols)

    :digraph.vertices(graph)
    |> Enum.map(fn x -> get_simple_cycles_for_vertex(graph, x) end)
    |> Enum.concat()
  end

  # generate graph from symbols
  @spec generate_graph([%{symbol: charlist(), baseAsset: charlist(), quoteAsset: charlist()}]) ::
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
  @spec get_simple_cycles_for_vertex(:digraph.graph(), :digraph.vertex()) :: [[:digraph.vertex()]]
  defp get_simple_cycles_for_vertex(graph, vertex) do
    neighbors =
      :digraph.out_neighbours(graph, vertex)
      |> Enum.map(fn x -> {x, [vertex]} end)

    dfs(graph, vertex, neighbors)
    |> List.flatten()
    |> Enum.chunk_while([], &chunk_fun/2, &after_fun/1)
  end

  @spec dfs(:digraph.graph(), :digraph.vertex(), [{:digraph.vertex(), [:digraph.vertex()]}], [
          :digraph.vertex()
        ]) :: [[:digraph.vertex()]]
  defp dfs(graph, start, neighbors \\ [], cycles \\ [])

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
end
