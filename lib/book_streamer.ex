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
    WebSockex.start_link(url, __MODULE__, %{pid: pid, symbols: symbols})
  end

  # handle messages from websocket server
  def handle_frame({_type, %{result: _, id: "sub_id"}}, state) do
    Logger.info("Subscribed!")
    {:ok, state}
  end

  def handle_frame({type, msg}, state) do
    Logger.info("Received Message - Type: #{inspect(type)} -- Message: #{inspect(msg)}")
    # TODO: parse the message and send the best ask price and quantity to opportunity watcher
    {:ok, state}
  end

  # handle asyc messages from WebSockex.cast() (user)
  def handle_cast({:send, {type, msg} = frame}, state) do
    Logger.info("Sending #{type} frame with payload: #{msg}")
    {:reply, frame, state}
  end

  # run when the connection is established
  def handle_connect(conn, state) do
    Logger.info("Connected!")
    subscribe_to_symbols(conn, state.symbols)
    {:ok, state}
  end

  defp subscribe_to_symbols(conn, symbols) do
    params =
      symbols
      |> String.downcase()
      |> Enum.map(fn s -> "#{s}@bookTicker" end)

    WebSockex.cast(conn, %{method: "SUBSCRIBE", params: params, id: "sub_id"})
  end
end
