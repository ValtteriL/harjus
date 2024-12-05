defmodule ArbmapperTest do
  use ExUnit.Case
  doctest Arbmapper

  test "generates correct trading paths" do
    trading_symbols = [
      %{symbol: "BTCETH", baseAsset: "BTC", quoteAsset: "ETH"},
      %{symbol: "ETHLTC", baseAsset: "ETH", quoteAsset: "LTC"},
      %{symbol: "LTCBTC", baseAsset: "LTC", quoteAsset: "BTC"}
    ]

    trading_paths = Arbmapper.generate_trading_paths(trading_symbols)

    assert trading_paths == [
             ["LTCBTC", "ETHLTC", "BTCETH"],
             ["ETHLTC", "BTCETH", "LTCBTC"],
             ["BTCETH", "LTCBTC", "ETHLTC"]
           ]
  end

  test "generates empty paths if no paths" do
    trading_symbols = [
      %{symbol: "BTCETH", baseAsset: "BTC", quoteAsset: "ETH"},
      %{symbol: "ETHLTC", baseAsset: "ETH", quoteAsset: "LTC"}
    ]

    trading_paths = Arbmapper.generate_trading_paths(trading_symbols)

    assert trading_paths == []
  end

  test "generates empty paths if no empty symbols" do
    trading_symbols = []

    trading_paths = Arbmapper.generate_trading_paths(trading_symbols)

    assert trading_paths == []
  end
end
