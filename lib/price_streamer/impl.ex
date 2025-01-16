defmodule PriceStreamer.Impl do
  @moduledoc """
  Process for streaming order book updates for trading symbols

  Subscribes to realtime updates on given symbols
  Relays the best ask price and quantity for each symbol to opportunity watcher
  """

  alias PriceStreamer.BinanceSpotStreams

  use WebSockex
  require Logger

  @doc """
  Start the book streamer
  """
  def start_link(symbols) do
    uri = Application.fetch_env!(:harjus, :binance_websocket_stream_uri)

    {:ok, ws_pid} = WebSockex.start_link(uri, __MODULE__, %{})

    Logger.debug("Subscribing to #{length(symbols)} symbols...")

    # subscribe to symbols
    WebSockex.send_frame(ws_pid, {:text, BinanceSpotStreams.subscribe_message(symbols)})

    {:ok, ws_pid}
  end

  # handle messages from websocket server

  # ping
  def handle_ping({:ping, id}, state) do
    {:reply, {:pong, id}, state}
  end

  # book ticker update
  def handle_frame({:text, msg}, state) do
    case BinanceSpotStreams.parse_message(msg) do
      {:error, error} ->
        Logger.debug(inspect(msg))
        Logger.error(inspect(error))

      {:sub_ack} ->
        Logger.info("Subscribed")
        :ok

      {:book_ticker_update, {symbol, best_ask_price, best_ask_qty, best_bid_price, best_bid_qty}} ->
        OpportunityWatcher.price_update(
          {symbol, best_ask_price, best_ask_qty, best_bid_price, best_bid_qty}
        )

        :ok

      {:unknown, message} ->
        Logger.error("Unknown message")
        Logger.debug(inspect(message))
    end

    {:ok, state}
  end

  def handle_frame({type, msg}, state) do
    Logger.error("Unhandled frame type: #{type}")
    Logger.debug(inspect(msg))
    {:ok, state}
  end
end
