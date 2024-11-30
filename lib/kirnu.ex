defmodule Kirnu do
  @moduledoc """
  Documentation for `Kirnu`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Kirnu.hello()
      :world

  """
  def hello do
    :world
  end

  def start do
    Websocket.start_link("wss://stream.binance.com:9443/ws/BTCUSD@bookTicker", %{})
  end

  @doc """
  Get all spot trading pairs from Binance.

  ## Examples

      iex> Kirnu.get_symbols()
      [%{symbol: "BTCUSD", baseAsset: "BTC", quoteAsset: "USD"}]
  """
  @spec get_symbols() :: [%{symbol: charlist(), baseAsset: charlist(), quoteAsset: charlist()}]
  defp get_symbols do
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
  @spec get_cycles(:digraph.graph()) :: [[:digraph.vertex()]]
  def get_cycles(graph) do
    # TODO
    :digraph.get_loops(graph)
  end

  @doc """
  Get trading pair symbols for all edges in a path, in order

  Used to find trading pair symbols for a cycle
  """
  @spec get_symbols_for_path(:digraph.graph(), [:digraph.vertex()]) :: [charlist()]
  def get_symbols_for_path(graph, path) do
    # TODO
    :digraph.get_vertices_for_path(graph, path)

    g
    |> :digraph.edges()
    |> Enum.map(fn x -> :digraph.edge(g, x) |> Tuple.to_list() |> List.last() end)
  end
end
