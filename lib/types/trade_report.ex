defmodule Types.TradeReport do
  @moduledoc """
  Trade report struct
  """

  @enforce_keys [
    :symbol,
    :position,
    :quantity_base,
    :quantity_quote,
    :quantity_fee,
    :fee_currency
  ]
  defstruct [
    :symbol,
    :position,
    :quantity_base,
    :quantity_quote,
    :quantity_fee,
    :fee_currency
  ]

  @type t :: %__MODULE__{
          symbol: String.t(),
          position: :long | :short,
          quantity_base: float(),
          quantity_quote: float(),
          quantity_fee: float(),
          fee_currency: String.t()
        }
end
