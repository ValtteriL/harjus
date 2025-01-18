defmodule OpportunityWatcher.State do
  @moduledoc """
  State of the opportunity watcher.
  """

  alias Types.TradingSymbol

  @enforce_keys [
    :pathid_to_path_map,
    :trading_symbol_to_price_qty_tuple,
    :symbol_to_pathids_map,
    :pathid_to_profit_cap_tuple,
    :symbol_to_trading_symbol_map,
    :min_capacity,
    :min_profit_percentage,
    :commission
  ]
  defstruct pathid_to_path_map: %{},
            trading_symbol_to_price_qty_tuple: %{},
            symbol_to_pathids_map: %{},
            pathid_to_profit_cap_tuple: %{},
            symbol_to_trading_symbol_map: %{},
            min_capacity: 0.0,
            min_profit_percentage: 0.0,
            commission: 0.0

  @type trading_path() :: [TradingSymbol.t()]
  @type price_qty_tuple() :: {price :: Decimal.t(), quantity :: Decimal.t()}
  @type profit_cap_tuple() :: {profit :: Decimal.t(), capacity :: Decimal.t()}

  @type t() :: %__MODULE__{
          pathid_to_path_map: %{integer() => trading_path()},
          trading_symbol_to_price_qty_tuple: %{TradingSymbol.t() => price_qty_tuple()},
          symbol_to_pathids_map: %{charlist() => [integer()]},
          pathid_to_profit_cap_tuple: %{integer() => profit_cap_tuple()},
          symbol_to_trading_symbol_map: %{
            charlist() => %{long: TradingSymbol.t(), short: TradingSymbol.t()}
          },
          min_capacity: Decimal.t(),
          min_profit_percentage: Decimal.t(),
          commission: Decimal.t()
        }
end
