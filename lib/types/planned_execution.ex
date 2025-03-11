defmodule Types.PlannedExecution do
  @moduledoc """
  Planned execution struct
  """
  alias Types.TradingSymbol

  @enforce_keys [
    # this is comparable to other planned executions, as it is in the comparison currency (BTC)
    :total_profit,
    :trades
  ]
  defstruct [
    :total_profit,
    :trades
  ]

  @type t :: %__MODULE__{
          total_profit: Decimal.t(),
          trades: [TradingSymbol.t()]
        }
end
