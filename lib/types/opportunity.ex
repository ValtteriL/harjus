defmodule Types.Opportunity do
  @moduledoc """
  Trade report struct
  """

  alias Types.TradingSymbol

  @enforce_keys [
    :path,
    :profit,
    :capacity
  ]
  defstruct [
    :path,
    :profit,
    :capacity
  ]

  @type t :: %__MODULE__{
          path: [TradingSymbol.t()],
          profit: Decimal.t(),
          capacity: Decimal.t()
        }
end
