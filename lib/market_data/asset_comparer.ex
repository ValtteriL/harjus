defmodule MarketData.AssetComparer do
  @moduledoc """
  Module for calculating relative value for assets

  Used by portfoliomanager to rank opportunities by value
  """

  @doc """
  calculate relative value for symbols
  """
  @spec calculate_relative_values(
          symbols :: [
            %{symbol: String.t(), baseAsset: charlist(), quoteAsset: charlist()}
          ],
          symbol_prices :: %{String.t() => Decimal.t()},
          comparison_asset :: String.t()
        ) ::
          %{symbol: String.t(), value: Decimal.t()}
  def calculate_relative_values(symbols, symbol_prices, comparison_asset) do
    # find price of every asset in comparison_asset

    # where comparison_asset is the quote asset
    btc_prices_base =
      symbols
      |> Enum.filter(fn x -> x.quoteAsset == comparison_asset end)
      |> Enum.map(fn %{symbol: s, baseAsset: b} -> {b, symbol_prices[s]} end)
      |> Enum.into(%{})

    # where comparison_asset is the base asset
    btc_prices_quote =
      symbols
      |> Enum.filter(fn x -> x.baseAsset == comparison_asset end)
      |> Enum.map(fn %{symbol: s, quoteAsset: q} -> {q, 1 / symbol_prices[s]} end)
      |> Enum.into(%{})

    # merge the two maps
    Map.merge(btc_prices_quote, btc_prices_base)
    # add the comparison_asset itself
    |> Map.put(comparison_asset, 1.0)
  end
end
