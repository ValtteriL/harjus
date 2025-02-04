defmodule Types.TradingSymbol do
  @moduledoc """
  Trading symbol module

  Note: base and quote assets are always swapped, so that quote asset is always the one we use in transactions.
  """

  @enforce_keys [
    :symbol,
    :position,
    :base_asset,
    :quote_asset,
    :quote_asset_increment,
    :quote_asset_precision
  ]
  defstruct [
    :symbol,
    :position,
    :base_asset,
    :quote_asset,
    :quote_asset_increment,
    :quote_asset_precision
  ]

  @type t :: %__MODULE__{
          symbol: String.t(),
          position: :long | :short,
          base_asset: String.t(),
          quote_asset: String.t(),
          quote_asset_increment: Decimal.t(),
          quote_asset_precision: integer()
        }
end
