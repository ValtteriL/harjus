defmodule PriceStreamer.Impl do
  @moduledoc """
  Implementation of the price streamer
  """

  alias PriceStreamer.Exchange

  @doc """
  Initiate starting state
  """
  def new(symbols = ["" <> _ | _]) do
    Exchange.new(symbols)
  end
end
