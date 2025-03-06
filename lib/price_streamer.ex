defmodule PriceStreamer do
  @moduledoc """
  Process for streaming order book updates for trading symbols

  Subscribes to realtime updates on given symbols
  Relays the best ask price and quantity for each symbol to opportunity watcher
  """

  alias PriceStreamer.Impl
  use Agent

  @doc """
  Start the book streamer

  Args:
    symbols: list of trading symbols to subscribe updates on
  """
  @spec start_link(symbols :: [String.t()]) :: {:ok, pid()}
  def start_link(symbols) do
    Agent.start_link(fn -> Impl.new(symbols) end, name: __MODULE__)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end
end
