defmodule MarketData.AssetComparer.Impl do
  @moduledoc """
  AssetComparer implementation
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
  def calculate_relative_values(
        symbols = [%{symbol: _, baseAsset: _, quoteAsset: _} | _],
        symbol_prices = %{},
        # string
        comparison_asset = "" <> _
      ) do
    # verify comparison_asset is base or quote asset in at least one symbols
    false =
      Enum.filter(symbols, fn x ->
        x.baseAsset == comparison_asset or x.quoteAsset == comparison_asset
      end)
      |> Enum.empty?()

    # check if comparison_asset is in symbols

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
      |> Enum.map(fn %{symbol: s, quoteAsset: q} -> {q, Decimal.div(1, symbol_prices[s])} end)
      |> Enum.into(%{})

    # merge the two maps
    Map.merge(btc_prices_quote, btc_prices_base)
    # add the comparison_asset itself
    |> Map.put(comparison_asset, Decimal.from_float(1.0))
  end
end
