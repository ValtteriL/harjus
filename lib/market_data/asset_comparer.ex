defmodule MarketData.AssetComparer do
  @moduledoc """
  Module for calculating relative value for assets

  Used by portfoliomanager to rank opportunities by value
  """

  alias MarketData.AssetComparer.Impl

  @doc """
  calculate relative value for symbols
  """
  @spec calculate_relative_values(
          symbols :: [
            %{symbol: String.t(), baseAsset: String.t(), quoteAsset: String.t()}
          ],
          symbol_prices :: %{String.t() => Decimal.t()},
          comparison_asset :: String.t()
        ) ::
          %{symbol: String.t(), value: Decimal.t()}
  defdelegate calculate_relative_values(symbols, symbol_prices, comparison_asset), to: Impl
end
