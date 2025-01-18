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
          quantity_base: Decimal.t(),
          quantity_quote: Decimal.t(),
          quantity_fee: Decimal.t(),
          fee_currency: String.t()
        }
end
