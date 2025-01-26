defmodule Types.PriceUpdate do
  @moduledoc """
  Price update struct
  """

  @enforce_keys [
    :symbol,
    :ask_price,
    :ask_qty,
    :bid_price,
    :bid_qty
  ]
  defstruct [
    :symbol,
    :ask_price,
    :ask_qty,
    :bid_price,
    :bid_qty
  ]

  @type t :: %__MODULE__{
          symbol: String.t(),
          ask_price: Decimal.t(),
          ask_qty: Decimal.t(),
          bid_price: Decimal.t(),
          bid_qty: Decimal.t()
        }
end
