defmodule PriceStreamer.Exchange do
  @moduledoc """
  Exchange behaviour
  """
  @callback new([String.t()]) :: :ok

  def new(symbols), do: impl().new(symbols)
  defp impl, do: Application.get_env(:harjus, :price_streamer_exchange)
end
