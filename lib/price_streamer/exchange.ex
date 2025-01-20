defmodule PriceStreamer.Exchange do
  @moduledoc """
  Exchange behaviour
  """
  @callback new([String.t()]) :: :ok
end
