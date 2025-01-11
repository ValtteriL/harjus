defmodule PriceStreamer do
  @moduledoc """
  Process for streaming order book updates for trading symbols

  Subscribes to realtime updates on given symbols
  Relays the best ask price and quantity for each symbol to opportunity watcher
  """

  alias PriceStreamer.Impl

  @doc """
  Start the book streamer

  Args:
    symbols: list of trading symbols to subscribe updates on
    is_prod: whether to connect to production or testnet
  """
  @spec start_link({symbols :: [String.t()], is_prod :: bool()}) :: {:ok, pid()}
  defdelegate start_link(args), to: Impl
end
