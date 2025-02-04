defmodule MarketData.ArbmapperTest do
  @moduledoc "Tests for Arbmapper"

  alias MarketData.Arbmapper
  alias MarketData.Types.Symbol
  alias Types.TradingSymbol

  use ExUnit.Case, async: true
  doctest Arbmapper
  use PropCheck

  property "symbol list cannot have more symbols than in input" do
    forall [trading_symbols, starting_symbols, depth] <- [
             trading_symbols(),
             non_empty(list(non_empty_string())),
             non_neg_integer()
           ] do
      {_paths, symbols} =
        Arbmapper.generate_trading_paths(trading_symbols,
          starting_symbols: starting_symbols,
          depth: depth
        )

      input_symbols = trading_symbols |> Enum.map(fn x -> x.symbol end) |> Enum.uniq()
      assert length(symbols) <= length(input_symbols)
    end
  end

  property "symbol list cannot have other symbols than in input" do
    forall [trading_symbols, starting_symbols, depth] <- [
             trading_symbols(),
             non_empty(list(non_empty_string())),
             non_neg_integer()
           ] do
      {_paths, symbols} =
        Arbmapper.generate_trading_paths(trading_symbols,
          starting_symbols: starting_symbols,
          depth: depth
        )

      input_symbols = trading_symbols |> Enum.map(fn x -> x.symbol end) |> Enum.uniq()
      assert Enum.all?(symbols, fn x -> Enum.member?(input_symbols, x) end)
    end
  end

  property "symbol list symbols must be unique" do
    forall [trading_symbols, starting_symbols, depth] <- [
             trading_symbols(),
             non_empty(list(non_empty_string())),
             non_neg_integer()
           ] do
      {_paths, symbols} =
        Arbmapper.generate_trading_paths(trading_symbols,
          starting_symbols: starting_symbols,
          depth: depth
        )

      assert Enum.uniq(symbols) == symbols
    end
  end

  property "trading paths must be unique" do
    forall [trading_symbols, starting_symbols, depth] <- [
             trading_symbols(),
             non_empty(list(non_empty_string())),
             non_neg_integer()
           ] do
      {paths, _symbols} =
        Arbmapper.generate_trading_paths(trading_symbols,
          starting_symbols: starting_symbols,
          depth: depth
        )

      assert Enum.uniq(paths) == paths
    end
  end

  property "trading paths only contain symbols from symbol list" do
    forall [trading_symbols, starting_symbols, depth] <- [
             trading_symbols(),
             non_empty(list(non_empty_string())),
             non_neg_integer()
           ] do
      {paths, symbols} =
        Arbmapper.generate_trading_paths(trading_symbols,
          starting_symbols: starting_symbols,
          depth: depth
        )

      assert Enum.all?(paths, fn x -> Enum.member?(symbols, x.symbol) end)
    end
  end

  property "trading paths start with starting symbols if defined" do
    forall [trading_symbols, starting_symbols, depth] <- [
             trading_symbols(),
             non_empty(list(non_empty_string())),
             non_neg_integer()
           ] do
      {paths, _symbols} =
        Arbmapper.generate_trading_paths(trading_symbols,
          starting_symbols: starting_symbols,
          depth: depth
        )

      assert Enum.all?(paths, fn x -> Enum.member?(starting_symbols, hd(x)) end)
    end
  end

  property "trading paths must be of length depth or less if defined" do
    forall [trading_symbols, starting_symbols, depth] <- [
             trading_symbols(),
             non_empty(list(non_empty_string())),
             non_neg_integer()
           ] do
      {paths, _symbols} =
        Arbmapper.generate_trading_paths(trading_symbols,
          starting_symbols: starting_symbols,
          depth: depth
        )

      assert Enum.all?(paths, fn x -> length(x) <= depth end)
    end
  end

  property "trading path contains a single trading symbol only once" do
    forall [trading_symbols, starting_symbols, depth] <- [
             trading_symbols(),
             non_empty(list(non_empty_string())),
             non_neg_integer()
           ] do
      {paths, _symbols} =
        Arbmapper.generate_trading_paths(trading_symbols,
          starting_symbols: starting_symbols,
          depth: depth
        )

      assert Enum.all?(paths, fn x -> Enum.uniq(x) == x end)
    end
  end

  ## Generators ##

  defp trading_symbols do
    let [
      symbol <- non_empty_string(),
      base_asset <- non_empty_string(),
      quote_asset <- non_empty_string(),
      quote_asset_precision <- pos_integer(),
      quote_asset_increment <- pos_decimal(),
      base_asset_precision <- pos_integer(),
      base_asset_increment <- pos_decimal()
    ] do
      let symbols <-
            non_empty(
              list(%Symbol{
                symbol: symbol,
                baseAsset: base_asset,
                quoteAsset: quote_asset,
                quoteAssetPrecision: quote_asset_precision,
                quoteAssetIncrement: quote_asset_increment,
                baseAssetPrecision: base_asset_precision,
                baseAssetIncrement: base_asset_increment
              })
            ) do
        symbols
      end
    end
  end

  defp pos_decimal do
    let float <- float(0.000001, :inf) do
      Decimal.from_float(float)
    end
  end

  defp non_empty_string do
    let charlist <- non_empty(elements(textdata())) do
      to_string(charlist)
    end
  end

  defp textdata do
    ~c"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789" ++
      ~c":;<=>?@ !#$%&'()*+-./[\\]^_`{|}~"
  end

  ## Unit tests ##

  test "generates correct trading paths and symbols" do
    trading_symbols = [
      %Symbol{
        symbol: "BTCETH",
        baseAsset: "BTC",
        quoteAsset: "ETH",
        quoteAssetPrecision: 8,
        quoteAssetIncrement: Decimal.new("0.01"),
        baseAssetPrecision: 8,
        baseAssetIncrement: Decimal.new("0.01")
      },
      %Symbol{
        symbol: "ETHLTC",
        baseAsset: "ETH",
        quoteAsset: "LTC",
        quoteAssetPrecision: 8,
        quoteAssetIncrement: Decimal.new("0.01"),
        baseAssetPrecision: 8,
        baseAssetIncrement: Decimal.new("0.01")
      },
      %Symbol{
        symbol: "LTCBTC",
        baseAsset: "LTC",
        quoteAsset: "BTC",
        quoteAssetPrecision: 8,
        quoteAssetIncrement: Decimal.new("0.01"),
        baseAssetPrecision: 8,
        baseAssetIncrement: Decimal.new("0.01")
      }
    ]

    trading_paths = Arbmapper.generate_trading_paths(trading_symbols)

    assert trading_paths ==
             {
               [
                 [
                   ts(%{
                     base_asset: "LTC",
                     position: :long,
                     quote_asset: "BTC",
                     symbol: "LTCBTC"
                   }),
                   ts(%{
                     base_asset: "ETH",
                     position: :long,
                     quote_asset: "LTC",
                     symbol: "ETHLTC"
                   }),
                   ts(%{
                     base_asset: "BTC",
                     position: :long,
                     quote_asset: "ETH",
                     symbol: "BTCETH"
                   })
                 ],
                 [
                   ts(%{
                     base_asset: "ETH",
                     position: :short,
                     quote_asset: "BTC",
                     symbol: "BTCETH"
                   }),
                   ts(%{
                     base_asset: "LTC",
                     position: :short,
                     quote_asset: "ETH",
                     symbol: "ETHLTC"
                   }),
                   ts(%{
                     base_asset: "BTC",
                     position: :short,
                     quote_asset: "LTC",
                     symbol: "LTCBTC"
                   })
                 ],
                 [
                   ts(%{
                     symbol: "LTCBTC",
                     position: :short,
                     base_asset: "BTC",
                     quote_asset: "LTC"
                   }),
                   ts(%{
                     symbol: "BTCETH",
                     position: :short,
                     base_asset: "ETH",
                     quote_asset: "BTC"
                   }),
                   ts(%{
                     symbol: "ETHLTC",
                     position: :short,
                     base_asset: "LTC",
                     quote_asset: "ETH"
                   })
                 ],
                 [
                   ts(%{
                     base_asset: "ETH",
                     position: :long,
                     quote_asset: "LTC",
                     symbol: "ETHLTC"
                   }),
                   ts(%{
                     base_asset: "BTC",
                     position: :long,
                     quote_asset: "ETH",
                     symbol: "BTCETH"
                   }),
                   ts(%{
                     base_asset: "LTC",
                     position: :long,
                     quote_asset: "BTC",
                     symbol: "LTCBTC"
                   })
                 ],
                 [
                   ts(%{
                     base_asset: "LTC",
                     position: :short,
                     quote_asset: "ETH",
                     symbol: "ETHLTC"
                   }),
                   ts(%{
                     base_asset: "BTC",
                     position: :short,
                     quote_asset: "LTC",
                     symbol: "LTCBTC"
                   }),
                   ts(%{
                     base_asset: "ETH",
                     position: :short,
                     quote_asset: "BTC",
                     symbol: "BTCETH"
                   })
                 ],
                 [
                   ts(%{
                     base_asset: "BTC",
                     position: :long,
                     quote_asset: "ETH",
                     symbol: "BTCETH"
                   }),
                   ts(%{
                     base_asset: "LTC",
                     position: :long,
                     quote_asset: "BTC",
                     symbol: "LTCBTC"
                   }),
                   ts(%{
                     base_asset: "ETH",
                     position: :long,
                     quote_asset: "LTC",
                     symbol: "ETHLTC"
                   })
                 ]
               ],
               ["LTCBTC", "ETHLTC", "BTCETH"]
             }

    symbols = [
      %Symbol{
        symbol: "BTCUSDT",
        baseAsset: "BTC",
        quoteAsset: "USDT",
        quoteAssetPrecision: 8,
        quoteAssetIncrement: Decimal.new("0.01"),
        baseAssetPrecision: 8,
        baseAssetIncrement: Decimal.new("0.01")
      },
      %Symbol{
        symbol: "ETHBTC",
        baseAsset: "ETH",
        quoteAsset: "BTC",
        quoteAssetPrecision: 8,
        quoteAssetIncrement: Decimal.new("0.01"),
        baseAssetPrecision: 8,
        baseAssetIncrement: Decimal.new("0.01")
      },
      %Symbol{
        symbol: "ETHUSDT",
        baseAsset: "ETH",
        quoteAsset: "USDT",
        quoteAssetPrecision: 8,
        quoteAssetIncrement: Decimal.new("0.01"),
        baseAssetPrecision: 8,
        baseAssetIncrement: Decimal.new("0.01")
      }
    ]

    assert Arbmapper.generate_trading_paths(symbols, starting_symbols: ["BTC"]) ==
             {[
                [
                  ts("ETH", "BTC", :long),
                  ts("USDT", "ETH", :short),
                  ts("BTC", "USDT", :long)
                ],
                [
                  ts("USDT", "BTC", :short),
                  ts("ETH", "USDT", :long),
                  ts("BTC", "ETH", :short)
                ]
              ], ["ETHBTC", "ETHUSDT", "BTCUSDT"]}
  end

  test "throws error if empty symbols" do
    assert_raise(FunctionClauseError, fn -> Arbmapper.generate_trading_paths([]) end)
  end

  defp ts(base_asset, quote_asset, :short) do
    %TradingSymbol{
      symbol: "#{quote_asset}#{base_asset}",
      position: :short,
      base_asset: base_asset,
      quote_asset: quote_asset,
      quote_asset_increment: Decimal.new("0.01"),
      quote_asset_precision: 8
    }
  end

  defp ts(base_asset, quote_asset, :long) do
    %TradingSymbol{
      symbol: "#{base_asset}#{quote_asset}",
      position: :long,
      base_asset: base_asset,
      quote_asset: quote_asset,
      quote_asset_increment: Decimal.new("0.01"),
      quote_asset_precision: 8
    }
  end

  defp ts(%{symbol: symbol, position: position, base_asset: base_aset, quote_asset: quote_asset}) do
    %TradingSymbol{
      symbol: symbol,
      position: position,
      base_asset: base_aset,
      quote_asset: quote_asset,
      quote_asset_increment: Decimal.new("0.01"),
      quote_asset_precision: 8
    }
  end
end
