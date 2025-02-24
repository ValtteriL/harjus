defmodule MarketData.Types.Symbol do
  @moduledoc """
  Symbol type
  """
  @type t :: %__MODULE__{
          symbol: String.t(),
          baseAsset: String.t(),
          quoteAsset: String.t(),
          baseAssetPrecision: integer(),
          quoteAssetPrecision: integer(),
          baseAssetIncrement: Decimal.t(),
          quoteAssetIncrement: Decimal.t(),
          minNotional: Decimal.t()
        }

  @enforce_keys [
    :symbol,
    :baseAsset,
    :quoteAsset,
    :baseAssetPrecision,
    :quoteAssetPrecision,
    :baseAssetIncrement,
    :quoteAssetIncrement,
    :minNotional
  ]
  defstruct [
    :symbol,
    :baseAsset,
    :quoteAsset,
    :baseAssetPrecision,
    :quoteAssetPrecision,
    :baseAssetIncrement,
    :quoteAssetIncrement,
    :minNotional
  ]
end
