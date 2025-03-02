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
                baseAssetIncrement: base_asset_increment,
                minNotional: const_increment()
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
    symbols = [
      %Symbol{
        symbol: "BTCUSDT",
        baseAsset: "BTC",
        quoteAsset: "USDT",
        quoteAssetPrecision: const_precision(),
        quoteAssetIncrement: const_increment(),
        baseAssetPrecision: const_precision(),
        baseAssetIncrement: const_increment(),
        minNotional: Decimal.from_float(0.0001)
      },
      %Symbol{
        symbol: "ETHBTC",
        baseAsset: "ETH",
        quoteAsset: "BTC",
        quoteAssetPrecision: const_precision(),
        quoteAssetIncrement: const_increment(),
        baseAssetPrecision: const_precision(),
        baseAssetIncrement: const_increment(),
        minNotional: Decimal.from_float(0.0001)
      },
      %Symbol{
        symbol: "ETHUSDT",
        baseAsset: "ETH",
        quoteAsset: "USDT",
        quoteAssetPrecision: const_precision(),
        quoteAssetIncrement: const_increment(),
        baseAssetPrecision: const_precision(),
        baseAssetIncrement: const_increment(),
        minNotional: Decimal.from_float(0.0001)
      }
    ]

    {paths, symbols} = Arbmapper.generate_trading_paths(symbols, starting_symbols: ["BTC"])

    # correct number of paths & symbols
    assert length(paths) == 2
    assert length(symbols) == 3

    # contains correct paths
    assert Enum.all?(paths, fn x ->
             Enum.member?(
               [
                 [
                   ts("ETH", "BTC", :long),
                   ts("ETH", "USDT", :short),
                   ts("BTC", "USDT", :long)
                 ],
                 [
                   ts("BTC", "USDT", :short),
                   ts("ETH", "USDT", :long),
                   ts("ETH", "BTC", :short)
                 ]
               ],
               x
             )
           end)

    # contains correct symbols
    assert Enum.all?(symbols, fn x ->
             Enum.member?(["ETHBTC", "ETHUSDT", "BTCUSDT"], x)
           end)
  end

  test "throws error if empty symbols" do
    assert_raise(FunctionClauseError, fn -> Arbmapper.generate_trading_paths([]) end)
  end

  defp ts(base_asset, quote_asset, position) do
    %TradingSymbol{
      symbol: "#{base_asset}#{quote_asset}",
      position: position,
      base_asset: base_asset,
      quote_asset: quote_asset,
      base_asset_increment: const_increment(),
      base_asset_precision: const_precision(),
      quote_asset_increment: const_increment(),
      quote_asset_precision: const_precision(),
      min_notional: Decimal.from_float(0.0001)
    }
  end

  defp const_precision do
    8
  end

  defp const_increment do
    Decimal.new("0.01")
  end
end
