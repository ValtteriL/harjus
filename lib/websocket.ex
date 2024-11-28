defmodule Websocket do
  use WebSockex
  require Logger

  @moduledoc """
  Documentation for `Websocket`.
  """

  @doc """
  Hello world.
  """
  def start_link(url, state) do
    WebSockex.start_link(url, __MODULE__, state)
  end

  # handle messages from websocket server
  def handle_frame({type, msg}, state) do
    Logger.info("Received Message - Type: #{inspect(type)} -- Message: #{inspect(msg)}")
    {:ok, state}
  end

  # handle asyc messages from WebSockex.cast() (user)
  def handle_cast({:send, {type, msg} = frame}, state) do
    Logger.info("Sending #{type} frame with payload: #{msg}")
    {:reply, frame, state}
  end

  # run when the connection is established
  def handle_connect(_conn, state) do
    Logger.info("Connected!")
    {:ok, state}
  end
end
