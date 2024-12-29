defmodule UserDataStreamer do
  @moduledoc "Client process for receiving messages from Binance WSuser data stream"

  use WebSockex
  require Logger

  def start_link(%{api_key: api_key, api_secret: api_secret, is_prod: is_prod}) do
    url =
      if is_prod do
        "wss://stream.binance.com:9443/ws/#{api_key}"
      else
        "wss://testnet.binance.vision/ws/#{api_key}"
      end

    {:ok, pid} =
      WebSockex.start_link(url, __MODULE__, %{api_key: api_key, api_secret: api_secret})

    subscribe(pid)
    {:ok, pid}
  end

  def handle_frame({:text, msg}, state) do
    case BinanceUserDataStream.parse_message(msg) do
      {:error, error} ->
        Logger.error(inspect(error))

      {:sub_ack} ->
        Logger.info("Subscribed to user data stream")

      {:user_data_event, event} ->
        Logger.info("Received user data event: #{inspect(event)}")

      {:unknown, message} ->
        Logger.error("Unknown message: #{inspect(message)}")
    end

    {:ok, state}
  end

  def handle_ping({:ping, id}, state) do
    {:reply, {:pong, id}, state}
  end

  def subscribe(pid) do
    WebSockex.send_frame(pid, {:text, BinanceUserDataStream.subscribe_message()})
  end
end
