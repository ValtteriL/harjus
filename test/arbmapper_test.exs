defmodule ArbmapperTest do
  use ExUnit.Case
  doctest Arbmapper

  test "generates trading paths" do
    trading_symbols = [
      %{symbol: "BTCETH", baseAsset: "BTC", quoteAsset: "ETH"},
      %{symbol: "ETHLTC", baseAsset: "ETH", quoteAsset: "LTC"},
      %{symbol: "LTCBTC", baseAsset: "LTC", quoteAsset: "BTC"}
    ]

    trading_paths = Arbmapper.generate_trading_paths(trading_symbols)

    assert trading_paths == [
             ["BTC", "LTC", "ETH", "BTC"],
             ["LTC", "ETH", "BTC", "LTC"],
             ["ETH", "BTC", "LTC", "ETH"]
           ]
  end
end
