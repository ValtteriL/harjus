defmodule Kirnu do
  @moduledoc """
  Documentation for `Kirnu`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Kirnu.hello()
      :world

  """
  def hello do
    :world
  end

  def start do
    Websocket.start_link("wss://stream.binance.com:9443/ws/BTCUSD@bookTicker", %{})
  end

end
