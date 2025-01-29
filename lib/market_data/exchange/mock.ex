defmodule MarketData.Exchange.Mock do
  @moduledoc "Mock for api calls on market data"

  @behaviour MarketData.Exchange

  # Get all trading pairs
  def get_symbols do
    [
      %{symbol: "BTCUSDT", baseAsset: "BTC", quoteAsset: "USDT"},
      %{symbol: "ETHBTC", baseAsset: "ETH", quoteAsset: "BTC"},
      %{symbol: "ETHUSDT", baseAsset: "ETH", quoteAsset: "USDT"}
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
