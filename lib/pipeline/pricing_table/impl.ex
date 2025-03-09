defmodule Pipeline.PricingTable.Impl do
  @moduledoc """
  Implementation of the pricing table
  """
  alias Types.TradingSymbol

  @spec new(trading_paths :: [TradingSymbol.t()]) :: map()
  def new(trading_paths) do
    # initialize id to path map
    id_to_path_map =
      trading_paths
      |> Enum.with_index()
      |> Enum.map(fn {path, index} -> {index, path} end)
      |> Map.new()

    # initialize symbol to pathids map
    symbol_to_ids_map =
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

    %{id_to_path_map: id_to_path_map, symbol_to_ids_map: symbol_to_ids_map}
  end

  @spec update_get_affected(
          pricing_table :: any(),
          update :: tuple()
        ) :: {map(), list()}
  def update_get_affected(
        state = %{id_to_path_map: id_to_path_map, symbol_to_ids_map: symbol_to_ids_map},
        update = {symbol, _ask_price, _ask_qty, _bid_price, _bid_qty}
      ) do
    affected_ids = symbol_to_ids_map[symbol]

    {affected_paths, new_id_to_path_map} =
      affected_ids
      |> Enum.map_reduce(id_to_path_map, fn id, map ->
        Map.get_and_update!(map, id, fn path ->
          new_path = update_path(path, update)
          # store updated, return updated
          {new_path, new_path}
        end)
      end)

    {%{state | id_to_path_map: new_id_to_path_map}, affected_paths}
  end

  defp update_path(path, update) do
    Enum.map(path, fn symbol ->
      update_symbol(symbol, update)
    end)
  end

  defp update_symbol(
         ts = %TradingSymbol{symbol: symbol, position: :long},
         {symbol, ask_price, ask_qty, _bid_price, _bid_qty}
       ) do
    %{ts | price: ask_price, qty: ask_qty}
  end

  defp update_symbol(
         ts = %TradingSymbol{symbol: symbol, position: :short},
         {symbol, _ask_price, _ask_qty, bid_price, bid_qty}
       ) do
    %{ts | price: bid_price, qty: bid_qty}
  end

  defp update_symbol(symbol, update), do: symbol
end
