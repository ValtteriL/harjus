defmodule WSSpotApiClient do
  @moduledoc """
  Client process to interact with the Binance WS Spot API

  Opens a persistent websocket connection to Binance and can then be used to send requests
  """
  use WebSockex
  require Logger

  @type trading_symbol() :: {charlist(), :long | :short}

  @spec start_link(is_prod :: bool()) :: {:ok, pid()}
  def start_link(is_prod) do
    GenServer.start_link(__MODULE__, is_prod, name: __MODULE__)
  end

  def init(is_prod) do
    url =
      if is_prod do
        "wss://ws-api.binance.com:443/ws-api/v3"
      else
        "wss://testnet.binance.vision/ws-api/v3"
      end

    {:ok, ws_pid} =
      WebSockex.start_link(url, __MODULE__, %{})

    {:ok, ws_pid}
  end

  # API

  @spec market_order(
          client :: pid(),
          trading_symbol :: trading_symbol(),
          quantity :: float(),
          api_key :: String.t(),
          api_secret :: String.t()
        ) :: :ok
  def market_order(client, trading_symbol, quantity, api_key, api_secret) do
    Logger.debug("Market order: #{trading_symbol} #{quantity}")

    order_request =
      BinanceWSSpotApi.market_order_request(trading_symbol, quantity, api_key, api_secret)

    WebSockex.send_frame(client, {:text, order_request})
  end

  # handle messages from websocket server

  # ping
  def handle_ping({:ping, id}, state) do
    {:reply, {:pong, id}, state}
  end

  # book ticker update
  def handle_frame({:text, msg}, state) do
    case BinanceWSSpotApi.parse_message(msg) do
      {:error, error} ->
        Logger.debug(inspect(msg))
        Logger.error(inspect(error))

      {:order_ack} ->
        Logger.debug("Order acknowledged")
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
