defmodule MarketData.Exchange do
  @moduledoc """
  Exchange behaviour
  """
  @callback get_symbols() :: [
              %{symbol: String.t(), baseAsset: String.t(), quoteAsset: String.t()}
            ]
  @callback get_symbol_prices() :: %{String.t() => Decimal.t()}
end
