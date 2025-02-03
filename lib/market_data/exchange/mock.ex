defmodule MarketData.Exchange.Mock do
  @moduledoc "Mock for api calls on market data"

  @behaviour MarketData.Exchange

  # Get all trading pairs
  def get_symbols do
    [
      %{
        symbol: "BTCUSDT",
        baseAsset: "BTC",
        quoteAsset: "USDT",
        baseAssetPrecision: 8,
        quoteAssetPrecision: 2,
        baseAssetIncrement: Decimal.from_float(0.00000001),
        quoteAssetIncrement: Decimal.from_float(0.01)
      },
      %{
        symbol: "ETHBTC",
        baseAsset: "ETH",
        quoteAsset: "BTC",
        baseAssetPrecision: 8,
        quoteAssetPrecision: 8,
        baseAssetIncrement: Decimal.from_float(0.00000001),
        quoteAssetIncrement: Decimal.from_float(0.00000001)
      },
      %{
        symbol: "ETHUSDT",
        baseAsset: "ETH",
        quoteAsset: "USDT",
        baseAssetPrecision: 8,
        quoteAssetPrecision: 2,
        baseAssetIncrement: Decimal.from_float(0.00000001),
        quoteAssetIncrement: Decimal.from_float(0.01)
      }
    ]
  end

  # get symbol prices
  def get_symbol_prices do
    %{
      "BTCUSDT" => Decimal.from_float(10_000.0),
      "ETHBTC" => Decimal.from_float(0.1),
      "ETHUSDT" => Decimal.from_float(1000.0)
    }
  end
end
