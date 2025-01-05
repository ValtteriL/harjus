defmodule TradingSymbol do
  @moduledoc """
  Trading symbol module
  """

  @enforce_keys [:symbol, :position]
  defstruct [:symbol, :position]

  @type t :: %__MODULE__{
          symbol: String.t(),
          position: :long | :short
        }
end
