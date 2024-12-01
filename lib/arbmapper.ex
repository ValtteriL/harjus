defmodule Arbmapper do
  @moduledoc """
  Module for finding arbitrage opportunities in Binance.
  """

  # Get all trading pairs from Binance
  @spec get_symbols() :: [%{symbol: charlist(), baseAsset: charlist(), quoteAsset: charlist()}]
  def get_symbols do
    {:ok, resp} = Req.get("https://api.binance.com/api/v3/exchangeInfo")

    resp.body["symbols"]
    |> Enum.map(fn x -> Map.take(x, ["symbol", "baseAsset", "quoteAsset"]) end)
  end

  @doc """
  Generate graph from trading pairs

  ## Examples

      iex> Kirnu.generate_graph([%{symbol: "BTCUSD", baseAsset: "BTC", quoteAsset: "USD"}])
      :digraph.graph()
  """
  @spec generate_graph([%{symbol: charlist(), baseAsset: charlist(), quoteAsset: charlist()}]) ::
          :digraph.graph()
  def generate_graph(symbols) do
    graph = :digraph.new()

    # Add symbols as vertices
    uniq_base_symbols = symbols |> Enum.map(fn x -> x["baseAsset"] end) |> Enum.uniq()

    for s <- uniq_base_symbols do
      :digraph.add_vertex(graph, s)
    end

    # Add trading pairs as edges
    for s <- symbols do
      :digraph.add_edge(graph, s["baseAsset"], s["quoteAsset"], s["symbol"])
    end

    graph
  end

  @doc """
  Get all unique cycles for every symbol in graph
  """
  @spec get_simple_cycles(:digraph.graph()) :: [[:digraph.vertex()]]
  def get_simple_cycles(graph) do
    # for every vertex in graph, find all simple cycles
    vertices = :digraph.vertices(graph)
    vertices |> Enum.map(fn x -> get_simple_cycles_for_symbol(graph, x) end) |> List.flatten
  end

  def get_simple_cycles_for_symbol(graph, symbol, visited \\ [], acc \\ []) do
    :digraph.out_neighbours(graph, symbol)
  end


  # take start node
  # if start node in neighbors, record loop
  # take

  @doc """
  Get trading pair symbols for all edges in a path, in order

  Used to find trading pair symbols for a cycle
  """
  # @spec get_symbols_for_path(:digraph.graph(), [:digraph.vertex()]) :: [charlist()]
  # def get_symbols_for_path(graph, path) do
  #  # TODO
  #  :digraph.get_vertices_for_path(graph, path)
  #
  #  g
  #  |> :digraph.edges()
  #  |> Enum.map(fn x -> :digraph.edge(g, x) |> Tuple.to_list() |> List.last() end)
  # end
end
