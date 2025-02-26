defmodule Types.PlannedTrade do
  @moduledoc """
  Sealed symbol module
  """

  alias Types.TradingSymbol

  @enforce_keys [
    :trading_symbol,
    :order_qty,
    :order_price
  ]
  defstruct [
    :trading_symbol,
    :order_qty,
    :order_price
  ]

  @type t :: %__MODULE__{
          trading_symbol: TradingSymbol.t(),
          order_qty: Decimal.t(),
          order_price: Decimal.t()
        }
end
