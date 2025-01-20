defmodule PriceStreamer.Impl do
  @moduledoc """
  Implementation of the price streamer
  """

  @exchange Application.compile_env(:harjus, :price_streamer_exchange)

  @doc """
  Initiate starting state
  """
  def new(symbols) do
    @exchange.new(symbols)
  end
end
