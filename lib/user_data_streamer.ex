defmodule UserDataStreamer do
  @moduledoc """
  Client process for receiving messages from Binance WSuser data stream

  https://github.com/binance/binance-spot-api-docs/blob/master/user-data-stream.md

  User Data Streams are accessed at /ws/<listenKey>
  
  TODO: MUST schedule keepalive/ping every 30 minutes!!

  """

  use WebSockex
  require Logger

  def start_link(%{is_prod: is_prod, listen_key: listen_key}) do

    url =
      if is_prod do
        "wss://stream.binance.com/ws/#{listen_key}"
      else
        "wss://stream.testnet.binance.vision/ws/#{listen_key}"
      end

    executor_pid = Process.whereis(Executor)

    {:ok, pid} =
      WebSockex.start_link(url, __MODULE__, %{pid: executor_pid})

    {:ok, pid}
  end

  def handle_frame({:text, msg}, state) do
    case BinanceUserDataStream.parse_message(msg) do
      {:error, error} ->
        Logger.error(inspect(error))

      {:account_update, update} ->
        # TODO: 

      {:order_update, update} ->
        # TODO: 

      {:key_expired} ->
        Logger.fatal("Listen key expired")

      {:unknown, message} ->
        Logger.error("Unknown message: #{inspect(message)}")
    end

    {:ok, state}
  end

  def handle_ping({:ping, id}, state) do
    {:reply, {:pong, id}, state}
  end
end
