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
    GenStage.start_link(Stage, Impl.new(symbols), name: __MODULE__)
  end

  @doc """
  Send a price update to the price streamer

  Args:
    pid: pid of the price streamer
    update: price update to send
  """
  @spec price_update(update :: Types.PriceUpdate.t()) :: :ok
  def price_update(update) do
    Metrics.report_price_update()
    GenStage.cast(__MODULE__, {:price_update, update})
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end
end
