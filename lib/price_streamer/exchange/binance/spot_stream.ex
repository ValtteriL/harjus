defmodule PriceStreamer.Exchange.Binance.SpotStream do
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
          | {:book_ticker_update, msg :: String.t()}
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

          # https://github.com/binance/binance-spot-api-docs/blob/master/web-socket-streams.md#individual-symbol-book-ticker-streams
          # contains also other fields, but assuming correct message based on this for performance reasons
          Map.has_key?(message, "B") ->
            # book ticker update
            {:book_ticker_update, msg}

          true ->
            {:unknown, message}
        end
    end
  end
end
