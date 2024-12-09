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
  @spec start_link(pid(), [charlist()], String.t()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(pid, symbols, url \\ "wss://testnet.binance.vision/ws/kek") do
    {:ok, pid} = WebSockex.start_link(url, __MODULE__, %{pid: pid})

    # subscribe to symbols
    params =
      symbols
      |> String.downcase()
      |> Enum.map(fn s -> "#{s}@bookTicker" end)
    WebSockex.send_frame(pid, {:text, Poison.encode!(%{method: "SUBSCRIBE", params: params, id: "sub_id"})})

    {:ok, pid}
  end

  # handle messages from websocket server

  # subscription ack
  def handle_frame({:text, %{result: null, id: "sub_id"}}, state) do
    Logger.info("Subscribed")
    {:ok, state}
  end

  # ping
  def handle_frame({:text, "PING"}, state) do
    Logger.info("PONG")
    {:reply, {:text, "PONG"}, state}
  end

  # book ticker update
  def handle_frame({type, msg}, state) do
    case Poison.decode(msg) do
      {:error, error} ->
        Logger.debug(inspect(msg))
        Logger.error(inspect(error))
      {:ok, message} ->
        case message["id"] do
          "sub_id" ->
            Logger.info("Subscribed")
            :ok
          else
            # TODO
        end
        # TODO
    end

    Logger.info("Received Message - Type: #{inspect(type)} -- Message: #{inspect(msg)}")
    # TODO: parse the message and send the best ask price and quantity to opportunity watcher
    {:ok, state}
  end

  # catch-all
  def handle_frame({type, msg}, state) do
    Logger.info("Received Message - Type: #{inspect(type)} -- Message: #{inspect(msg)}")
    # TODO: parse the message and send the best ask price and quantity to opportunity watcher
    {:ok, state}
  end
end
