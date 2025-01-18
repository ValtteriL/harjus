defmodule PriceStreamer.BinanceSpotStreams do
  @moduledoc """
  Functions for parsing and constructing Binance Spot Websocket messages.

  Websocket stream docs:
  https://developers.binance.com/docs/binance-spot-api-docs/web-socket-streams
  """

  @spec subscribe_message(symbols :: [String.t()]) :: String.t()
  def subscribe_message(symbols) do
    params =
      symbols
      |> Enum.map(fn s -> "#{String.downcase(s)}@bookTicker" end)

    Poison.encode!(%{method: "SUBSCRIBE", params: params, id: "sub_id"})
  end

  @spec parse_message(msg :: String.t()) ::
          {:error, any()}
          | {:sub_ack}
          | {:book_ticker_update,
             {symbol :: charlist(), best_ask_price :: Decimal.t(), best_ask_qty :: Decimal.t(),
              best_bid_price :: Decimal.t(), best_bid_qty :: Decimal.t()}}
          | {:unknown, map()}
  def parse_message(msg) do
    case Poison.decode(msg) do
      {:error, error} ->
        {:error, error}

      {:ok, message} ->
        cond do
          message["id"] == "sub_id" and message["result"] == nil ->
            # subscription ack
            {:sub_ack}

          has_keys?(message, ["u", "s", "b", "B", "a", "A"]) ->
            symbol = message["s"]
            best_ask_price = Decimal.new(message["a"])
            best_ask_qty = Decimal.new(message["A"])
            best_bid_price = Decimal.new(message["b"])
            best_bid_qty = Decimal.new(message["B"])

            {:book_ticker_update,
             {symbol, best_ask_price, best_ask_qty, best_bid_price, best_bid_qty}}

          true ->
            {:unknown, message}
        end
    end
  end

  @spec has_keys?(map :: map(), keys :: [String.t()]) :: boolean()
  defp has_keys?(map, keys) do
    Enum.all?(keys, &Map.has_key?(map, &1))
  end
end
