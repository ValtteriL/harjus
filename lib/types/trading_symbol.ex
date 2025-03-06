defmodule Types.TradingSymbol do
  @moduledoc """
  Trading symbol module
  """

  @enforce_keys [
    :symbol,
    :position,
    :base_asset,
    :quote_asset,
    :base_asset_increment,
    :base_asset_precision,
    :quote_asset_increment,
    :quote_asset_precision,
    :min_notional,
    :ask_price,
    :ask_qty,
    :bid_price,
    :bid_qty
  ]
  defstruct [
    :symbol,
    :position,
    :base_asset,
    :quote_asset,
    :base_asset_increment,
    :base_asset_precision,
    :quote_asset_increment,
    :quote_asset_precision,
    :min_notional,
    :ask_price,
    :ask_qty,
    :bid_price,
    :bid_qty
  ]

  @type t :: %__MODULE__{
          symbol: String.t(),
          position: :long | :short,
          base_asset: String.t(),
          quote_asset: String.t(),
          base_asset_increment: Decimal.t(),
          base_asset_precision: integer(),
          quote_asset_increment: Decimal.t(),
          quote_asset_precision: integer(),
          min_notional: Decimal.t(),
          ask_price: Decimal.t(),
          ask_qty: Decimal.t(),
          bid_price: Decimal.t(),
          bid_qty: Decimal.t()
        }
end
