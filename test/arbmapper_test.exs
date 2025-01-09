defmodule ArbmapperTest do
  @moduledoc "Tests for Arbmapper"
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
                 [
                   %TradingSymbol{symbol: "LTCBTC", position: :long},
                   %TradingSymbol{symbol: "ETHLTC", position: :long},
                   %TradingSymbol{symbol: "BTCETH", position: :long}
                 ],
                 [
                   %TradingSymbol{symbol: "BTCETH", position: :short},
                   %TradingSymbol{symbol: "ETHLTC", position: :short},
                   %TradingSymbol{symbol: "LTCBTC", position: :short}
                 ],
                 [
                   %TradingSymbol{symbol: "LTCBTC", position: :short},
                   %TradingSymbol{symbol: "BTCETH", position: :short},
                   %TradingSymbol{symbol: "ETHLTC", position: :short}
                 ],
                 [
                   %TradingSymbol{symbol: "ETHLTC", position: :long},
                   %TradingSymbol{symbol: "BTCETH", position: :long},
                   %TradingSymbol{symbol: "LTCBTC", position: :long}
                 ],
                 [
                   %TradingSymbol{symbol: "ETHLTC", position: :short},
                   %TradingSymbol{symbol: "LTCBTC", position: :short},
                   %TradingSymbol{symbol: "BTCETH", position: :short}
                 ],
                 [
                   %TradingSymbol{symbol: "BTCETH", position: :long},
                   %TradingSymbol{symbol: "LTCBTC", position: :long},
                   %TradingSymbol{symbol: "ETHLTC", position: :long}
                 ]
               ],
               ["LTCBTC", "ETHLTC", "BTCETH"]
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
                [
                  %TradingSymbol{symbol: "LTCBTC", position: :long},
                  %TradingSymbol{symbol: "ETHLTC", position: :long},
                  %TradingSymbol{symbol: "BTCETH", position: :long}
                ],
                [
                  %TradingSymbol{symbol: "BTCETH", position: :short},
                  %TradingSymbol{symbol: "ETHLTC", position: :short},
                  %TradingSymbol{symbol: "LTCBTC", position: :short}
                ]
              ], ["LTCBTC", "ETHLTC", "BTCETH"]}
  end

  test "filters paths and symbols correctly using depth" do
    trading_symbols = [
      %{symbol: "BTCETH", baseAsset: "BTC", quoteAsset: "ETH"},
      %{symbol: "ETHLTC", baseAsset: "ETH", quoteAsset: "LTC"},
      %{symbol: "LTCBTC", baseAsset: "LTC", quoteAsset: "BTC"}
    ]

    trading_paths =
      Arbmapper.generate_trading_paths(trading_symbols, starting_symbols: [], depth: 1)

    # arbmapper skips paths of length 1, thus now should be compeltely empty
    assert trading_paths ==
             {
               [],
               []
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
