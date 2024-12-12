defmodule ArbmapperTest do
  use ExUnit.Case
  doctest Arbmapper

  test "generates correct trading paths and symbols" do
    trading_symbols = [
      %{symbol: "BTCETH", baseAsset: "BTC", quoteAsset: "ETH"},
      %{symbol: "ETHLTC", baseAsset: "ETH", quoteAsset: "LTC"},
      %{symbol: "LTCBTC", baseAsset: "LTC", quoteAsset: "BTC"}
    ]

    trading_paths = Arbmapper.generate_trading_paths(trading_symbols)

    assert trading_paths ==
             {[
                ["LTCBTC", "ETHLTC", "BTCETH"],
                ["ETHLTC", "BTCETH", "LTCBTC"],
                ["BTCETH", "LTCBTC", "ETHLTC"]
              ], ["LTCBTC", "ETHLTC", "BTCETH"]}
  end

  test "filters paths and symbols correctly using starting symbols" do
    trading_symbols = [
      %{symbol: "BTCETH", baseAsset: "BTC", quoteAsset: "ETH"},
      %{symbol: "ETHLTC", baseAsset: "ETH", quoteAsset: "LTC"},
      %{symbol: "LTCBTC", baseAsset: "LTC", quoteAsset: "BTC"}
    ]

    trading_paths = Arbmapper.generate_trading_paths(trading_symbols, ["BTC"])

    assert trading_paths ==
             {[
                ["LTCBTC", "ETHLTC", "BTCETH"]
              ], ["LTCBTC", "ETHLTC", "BTCETH"]}
  end

  test "filters paths and symbols correctly using depth" do
    trading_symbols = [
      %{symbol: "BTCETH", baseAsset: "BTC", quoteAsset: "ETH"},
      %{symbol: "ETHBTC", baseAsset: "ETH", quoteAsset: "BTC"},
      %{symbol: "ETHLTC", baseAsset: "ETH", quoteAsset: "LTC"},
      %{symbol: "LTCBTC", baseAsset: "LTC", quoteAsset: "BTC"}
    ]

    trading_paths = Arbmapper.generate_trading_paths(trading_symbols, [], 1)

    assert trading_paths ==
             {[
                ["ETHBTC", "BTCETH"],
                ["BTCETH", "ETHBTC"]
              ], ["ETHBTC", "BTCETH"]}
  end

  test "generates empty paths if no paths" do
    trading_symbols = [
      %{symbol: "BTCETH", baseAsset: "BTC", quoteAsset: "ETH"},
      %{symbol: "ETHLTC", baseAsset: "ETH", quoteAsset: "LTC"}
    ]

    trading_paths = Arbmapper.generate_trading_paths(trading_symbols)

    assert trading_paths == {[], []}
  end

  test "generates empty paths if empty symbols" do
    trading_symbols = []

    trading_paths = Arbmapper.generate_trading_paths(trading_symbols)

    assert trading_paths == {[], []}
  end
end
