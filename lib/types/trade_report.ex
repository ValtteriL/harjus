defmodule Types.TradeReport do
  @moduledoc """
  Trade report struct
  """

  alias Types.TradeReport.Fee

  @enforce_keys [
    :symbol,
    :position,
    :quantity_base,
    :quantity_quote,
    :fees
  ]
  defstruct [
    :symbol,
    :position,
    :quantity_base,
    :quantity_quote,
    :fees
  ]

  @type t :: %__MODULE__{
          symbol: String.t(),
          position: :long | :short,
          quantity_base: Decimal.t(),
          quantity_quote: Decimal.t(),
          fees: [Fee.t()]
        }

  defmodule Fee do
    @moduledoc "fee group"
    @type t :: %__MODULE__{}

    @enforce_keys [
      :fee_currency,
      :fee_amount
    ]
    defstruct [
      :fee_currency,
      :fee_amount
    ]
  end
end
