defmodule TradingSymbol do
  @moduledoc """
  Trading symbol module
  """

  @enforce_keys [:symbol, :position, :base_asset, :quote_asset]
  defstruct [:symbol, :position, :base_asset, :quote_asset]

  @type t :: %__MODULE__{
          symbol: String.t(),
          position: :long | :short,
          base_asset: String.t(),
          quote_asset: String.t()
        }
end
