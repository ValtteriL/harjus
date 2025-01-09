defmodule AssetComparerTest do
  @moduledoc """
  Tests for the Balance module
  """
  use ExUnit.Case
  doctest AssetComparer

  test "calculates relative values correctly" do
    symbols = [
      %{symbol: "BTCUSDT", baseAsset: "BTC", quoteAsset: "USDT"},
      %{symbol: "ETHBTC", baseAsset: "ETH", quoteAsset: "BTC"},
      %{symbol: "ETHUSDT", baseAsset: "ETH", quoteAsset: "USDT"}
    ]

    symbol = "BTC"

    symbol_prices = %{
      "BTCUSDT" => 50_000.0,
      "ETHBTC" => 0.05,
      "ETHUSDT" => 2500.0
    }

    expected = %{
      "BTC" => 1.0,
      "USDT" => 1 / 50_000.0,
      "ETH" => 0.05
    }

    assert AssetComparer.calculate_relative_values(symbols, symbol_prices, symbol) == expected
  end
end
