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
             {
               [
                 [{"BTCETH", :short}, {"BTCETH", :long}],
                 [{"LTCBTC", :long}, {"ETHLTC", :long}, {"BTCETH", :long}],
                 [{"BTCETH", :short}, {"ETHLTC", :short}, {"LTCBTC", :short}],
                 [{"LTCBTC", :long}, {"LTCBTC", :short}],
                 [{"LTCBTC", :short}, {"BTCETH", :short}, {"ETHLTC", :short}],
                 [{"ETHLTC", :long}, {"ETHLTC", :short}],
                 [{"ETHLTC", :long}, {"BTCETH", :long}, {"LTCBTC", :long}],
                 [{"LTCBTC", :short}, {"LTCBTC", :long}],
                 [{"BTCETH", :long}, {"BTCETH", :short}],
                 [{"ETHLTC", :short}, {"LTCBTC", :short}, {"BTCETH", :short}],
                 [{"ETHLTC", :short}, {"ETHLTC", :long}],
                 [{"BTCETH", :long}, {"LTCBTC", :long}, {"ETHLTC", :long}]
               ],
               ["BTCETH", "LTCBTC", "ETHLTC"]
             }
  end

  test "filters paths and symbols correctly using starting symbols" do
    trading_symbols = [
      %{symbol: "BTCETH", baseAsset: "BTC", quoteAsset: "ETH"},
      %{symbol: "ETHLTC", baseAsset: "ETH", quoteAsset: "LTC"},
      %{symbol: "LTCBTC", baseAsset: "LTC", quoteAsset: "BTC"}
    ]

    trading_paths = Arbmapper.generate_trading_paths(trading_symbols, starting_symbols: ["BTC"])

    assert trading_paths ==
             {[
                [{"BTCETH", :short}, {"BTCETH", :long}],
                [{"LTCBTC", :long}, {"ETHLTC", :long}, {"BTCETH", :long}],
                [{"BTCETH", :short}, {"ETHLTC", :short}, {"LTCBTC", :short}],
                [{"LTCBTC", :long}, {"LTCBTC", :short}]
              ], ["BTCETH", "LTCBTC", "ETHLTC"]}
  end

  test "filters paths and symbols correctly using depth" do
    trading_symbols = [
      %{symbol: "BTCETH", baseAsset: "BTC", quoteAsset: "ETH"},
      %{symbol: "ETHLTC", baseAsset: "ETH", quoteAsset: "LTC"},
      %{symbol: "LTCBTC", baseAsset: "LTC", quoteAsset: "BTC"}
    ]

    trading_paths =
      Arbmapper.generate_trading_paths(trading_symbols, starting_symbols: [], depth: 1)

    assert trading_paths ==
             {
               [
                 [{"BTCETH", :short}, {"BTCETH", :long}],
                 [{"LTCBTC", :long}, {"LTCBTC", :short}],
                 [{"ETHLTC", :long}, {"ETHLTC", :short}],
                 [{"LTCBTC", :short}, {"LTCBTC", :long}],
                 [{"BTCETH", :long}, {"BTCETH", :short}],
                 [{"ETHLTC", :short}, {"ETHLTC", :long}]
               ],
               ["BTCETH", "LTCBTC", "ETHLTC"]
             }
  end

  test "generates empty paths if no paths" do
    trading_symbols = []

    trading_paths = Arbmapper.generate_trading_paths(trading_symbols)

    assert trading_paths == {[], []}
  end

  test "generates empty paths if empty symbols" do
    trading_symbols = []

    trading_paths = Arbmapper.generate_trading_paths(trading_symbols)

    assert trading_paths == {[], []}
  end
end
