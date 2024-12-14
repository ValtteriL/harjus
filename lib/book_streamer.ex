defmodule BookStreamer do
  @moduledoc """
  Process for streaming order book updates for trading symbols

  Subscribes to realtime updates on given symbols
  Relays the best ask price and quantity for each symbol to opportunity watcher
  """

  use WebSockex
  require Logger

  @doc """
  Start the book streamer

  Args:
    pid: pid of the process to send book updates
    symbols: list of trading symbols to subscribe updates on
    url: websocket url to connect to
  """
  @spec start_link(
          symbols :: [String.t()],
          url ::
            String.t()
            | %WebSockex.Conn{
                cacerts: any(),
                conn_mod: :gen_tcp | :ssl,
                extra_headers: [{any(), any()}],
                host: binary(),
                insecure: any(),
                path: binary(),
                port: non_neg_integer(),
                query: nil | binary(),
                resp_headers: [{any(), any()}],
                socket: any(),
                socket_connect_timeout: non_neg_integer(),
                socket_recv_timeout: non_neg_integer(),
                ssl_options: any(),
                transport: :ssl | :tcp
              }
        ) :: {:ok, pid()}
  def start_link(symbols, url \\ "wss://testnet.binance.vision/ws/kek") do
    pid = Process.whereis(OpportunityWatcher)
    {:ok, ws_pid} = WebSockex.start_link(url, __MODULE__, %{pid: pid})

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

      {:book_ticker_update, {symbol, best_ask_price, best_ask_qty}} ->
        OpportunityWatcher.update_symbol(state.pid, {symbol, best_ask_price, best_ask_qty})
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
