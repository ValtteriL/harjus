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
      "BTCUSDT" => 10_000.0,
      "ETHBTC" => 0.1,
      "ETHUSDT" => 1000.0
    }
  end
end
