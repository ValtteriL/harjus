defmodule MarketData.Exchange do
  @moduledoc """
  Exchange behaviour
  """
  @callback get_symbols() :: [
              %{
                symbol: String.t(),
                baseAsset: String.t(),
                quoteAsset: String.t(),
                baseAssetPrecision: integer(),
                quoteAssetPrecision: integer(),
                baseAssetIncrement: Decimal.t(),
                quoteAssetIncrement: Decimal.t()
              }
            ]
  @callback get_symbol_prices() :: %{String.t() => Decimal.t()}

  def get_symbols, do: impl().get_symbols()
  def get_symbol_prices, do: impl().get_symbol_prices()
  defp impl, do: Application.get_env(:harjus, :market_data_exchange)
end
