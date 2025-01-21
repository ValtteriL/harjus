defmodule MarketData.ArbmapperTest do
  @moduledoc "Tests for Arbmapper"

  alias MarketData.Arbmapper
  alias Types.TradingSymbol

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
                   %TradingSymbol{
                     symbol: "LTCBTC",
                     position: :long,
                     base_asset: "LTC",
                     quote_asset: "BTC"
                   },
                   %TradingSymbol{
                     symbol: "ETHLTC",
                     position: :long,
                     base_asset: "ETH",
                     quote_asset: "LTC"
                   },
                   %TradingSymbol{
                     symbol: "BTCETH",
                     position: :long,
                     base_asset: "BTC",
                     quote_asset: "ETH"
                   }
                 ],
                 [
                   %TradingSymbol{
                     symbol: "BTCETH",
                     position: :short,
                     base_asset: "ETH",
                     quote_asset: "BTC"
                   },
                   %TradingSymbol{
                     symbol: "ETHLTC",
                     position: :short,
                     base_asset: "LTC",
                     quote_asset: "ETH"
                   },
                   %TradingSymbol{
                     symbol: "LTCBTC",
                     position: :short,
                     base_asset: "BTC",
                     quote_asset: "LTC"
                   }
                 ],
                 [
                   %TradingSymbol{
                     symbol: "LTCBTC",
                     position: :short,
                     base_asset: "BTC",
                     quote_asset: "LTC"
                   },
                   %TradingSymbol{
                     symbol: "BTCETH",
                     position: :short,
                     base_asset: "ETH",
                     quote_asset: "BTC"
                   },
                   %TradingSymbol{
                     symbol: "ETHLTC",
                     position: :short,
                     base_asset: "LTC",
                     quote_asset: "ETH"
                   }
                 ],
                 [
                   %TradingSymbol{
                     symbol: "ETHLTC",
                     position: :long,
                     base_asset: "ETH",
                     quote_asset: "LTC"
                   },
                   %TradingSymbol{
                     symbol: "BTCETH",
                     position: :long,
                     base_asset: "BTC",
                     quote_asset: "ETH"
                   },
                   %TradingSymbol{
                     symbol: "LTCBTC",
                     position: :long,
                     base_asset: "LTC",
                     quote_asset: "BTC"
                   }
                 ],
                 [
                   %TradingSymbol{
                     symbol: "ETHLTC",
                     position: :short,
                     base_asset: "LTC",
                     quote_asset: "ETH"
                   },
                   %TradingSymbol{
                     symbol: "LTCBTC",
                     position: :short,
                     base_asset: "BTC",
                     quote_asset: "LTC"
                   },
                   %TradingSymbol{
                     symbol: "BTCETH",
                     position: :short,
                     base_asset: "ETH",
                     quote_asset: "BTC"
                   }
                 ],
                 [
                   %TradingSymbol{
                     symbol: "BTCETH",
                     position: :long,
                     base_asset: "BTC",
                     quote_asset: "ETH"
                   },
                   %TradingSymbol{
                     symbol: "LTCBTC",
                     position: :long,
                     base_asset: "LTC",
                     quote_asset: "BTC"
                   },
                   %TradingSymbol{
                     symbol: "ETHLTC",
                     position: :long,
                     base_asset: "ETH",
                     quote_asset: "LTC"
                   }
                 ]
               ],
               ["LTCBTC", "ETHLTC", "BTCETH"]
             }

    symbols = [
      %{symbol: "BTCUSDT", baseAsset: "BTC", quoteAsset: "USDT"},
      %{symbol: "ETHBTC", baseAsset: "ETH", quoteAsset: "BTC"},
      %{symbol: "ETHUSDT", baseAsset: "ETH", quoteAsset: "USDT"}
    ]

    assert Arbmapper.generate_trading_paths(symbols, starting_symbols: ["BTC"]) ==
             {[
                [
                  %Types.TradingSymbol{
                    base_asset: "ETH",
                    position: :long,
                    quote_asset: "BTC",
                    symbol: "ETHBTC"
                  },
                  %Types.TradingSymbol{
                    base_asset: "USDT",
                    position: :short,
                    quote_asset: "ETH",
                    symbol: "ETHUSDT"
                  },
                  %Types.TradingSymbol{
                    base_asset: "BTC",
                    position: :long,
                    quote_asset: "USDT",
                    symbol: "BTCUSDT"
                  }
                ],
                [
                  %Types.TradingSymbol{
                    symbol: "BTCUSDT",
                    position: :short,
                    base_asset: "USDT",
                    quote_asset: "BTC"
                  },
                  %Types.TradingSymbol{
                    symbol: "ETHUSDT",
                    position: :long,
                    base_asset: "ETH",
                    quote_asset: "USDT"
                  },
                  %Types.TradingSymbol{
                    symbol: "ETHBTC",
                    position: :short,
                    base_asset: "BTC",
                    quote_asset: "ETH"
                  }
                ]
              ], ["ETHBTC", "ETHUSDT", "BTCUSDT"]}
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
                  %TradingSymbol{
                    symbol: "LTCBTC",
                    position: :long,
                    base_asset: "LTC",
                    quote_asset: "BTC"
                  },
                  %TradingSymbol{
                    symbol: "ETHLTC",
                    position: :long,
                    base_asset: "ETH",
                    quote_asset: "LTC"
                  },
                  %TradingSymbol{
                    symbol: "BTCETH",
                    position: :long,
                    base_asset: "BTC",
                    quote_asset: "ETH"
                  }
                ],
                [
                  %TradingSymbol{
                    symbol: "BTCETH",
                    position: :short,
                    base_asset: "ETH",
                    quote_asset: "BTC"
                  },
                  %TradingSymbol{
                    symbol: "ETHLTC",
                    position: :short,
                    base_asset: "LTC",
                    quote_asset: "ETH"
                  },
                  %TradingSymbol{
                    symbol: "LTCBTC",
                    position: :short,
                    base_asset: "BTC",
                    quote_asset: "LTC"
                  }
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
