defmodule PriceStreamer do
  @moduledoc """
  Process for streaming order book updates for trading symbols

  Subscribes to realtime updates on given symbols
  Relays the best ask price and quantity for each symbol to opportunity watcher
  """

  alias PriceStreamer.Impl
  alias PriceStreamer.Stage

  @doc """
  Start the book streamer

  Args:
    symbols: list of trading symbols to subscribe updates on
  """
  @spec start_link(symbols :: [String.t()]) :: {:ok, pid()}
  def start_link(symbols) do
    GenStage.start_link(Stage, Impl.new(symbols))
  end

  @doc """
  Send a price update to the price streamer

  Args:
    pid: pid of the price streamer
    update: price update to send
  """
  @spec price_update(pid :: pid(), update :: Types.PriceUpdate.t()) :: :ok
  def price_update(pid, update) do
    GenStage.cast(pid, {:price_update, update})
  end
end
