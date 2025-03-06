defmodule Types.PlannedExecution do
  @moduledoc """
  Planned execution struct
  """
  alias Types.PlannedTrade
  alias Types.TradingSymbol

  @enforce_keys [
    :total_profit,
    :trades
  ]
  defstruct [
    :total_profit,
    :trades
  ]

  @type t :: %__MODULE__{
          total_profit: Decimal.t(),
          trades: [PlannedTrade.t()]
        }
end
