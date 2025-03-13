defmodule MarketDataTest do
  @moduledoc "Tests for MarketData"

  use ExUnit.Case, async: true
  use PropCheck
  import Mox

  alias MarketData.Types.Symbol

  doctest MarketData

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  property "generates correct trading paths and symbols" do
    forall [
             {symbols, symbol_prices, comparison_asset},
             starting_symbols,
             depth,
             blacklisted_starting_symbols
           ] <- [
             gen_symbols_prices_asset(),
             non_empty(list(non_empty_string())),
             positive_integer(),
             non_empty(list(non_empty_string()))
           ] do
      # setup mock
      MarketData.Exchange.TestMock
      |> expect(:get_symbols, fn -> symbols end)
      |> expect(:get_symbol_prices, fn -> symbol_prices end)

      md = MarketData.new()

      {paths, symbols} =
        MarketData.trading_paths(md, starting_symbols, depth, blacklisted_starting_symbols)

      relative_prices = MarketData.relative_values(md, comparison_asset)

      input_symbols = symbols |> Enum.map(fn x -> x.symbol end) |> Enum.uniq()

      # symbol list cannot have more symbols than in input
      assert length(symbols) <= length(input_symbols)

      # symbol list cannot have other symbols than in input
      assert Enum.all?(symbols, fn x -> Enum.member?(input_symbols, x) end)

      # symbol list symbols must be unique
      assert Enum.uniq(symbols) == symbols

      # trading paths must be unique
      assert Enum.uniq(paths) == paths

      # trading paths can only contain symbols from symbol list
      assert Enum.all?(paths, fn x -> Enum.member?(symbols, x.symbol) end)

      # trading paths must start with starting symbols if defined
      assert Enum.all?(paths, fn x -> Enum.member?(starting_symbols, hd(x)) end)

      # trading paths must never start with blacklisted starting symbols
      assert Enum.all?(paths, fn x -> !Enum.member?(blacklisted_starting_symbols, hd(x)) end)

      # trading paths must be of length depth or less if defined
      assert Enum.all?(paths, fn x -> length(x) <= depth end)

      # trading path can contain a single trading symbol only once
      assert Enum.all?(paths, fn x -> Enum.uniq(x) == x end)

      # output map must include all symbols as keys
      assert Enum.all?(symbols, fn x ->
               Map.has_key?(relative_prices, x.baseAsset) and
                 Map.has_key?(relative_prices, x.quoteAsset)
             end)
    end
  end

  ## Generators ##

  defp gen_symbols_prices_asset do
    let symbols <- trading_symbols() do
      let price <- non_neg_float() do
        let symbol_prices <-
              symbols
              |> Enum.map(fn x -> x.symbol end)
              |> Enum.map(fn x -> {x, Decimal.from_float(price)} end)
              |> Enum.into(%{}) do
          let comparison_asset <- symbols |> Enum.random() |> Map.fetch!(:baseAsset) do
            {symbols, symbol_prices, comparison_asset}
          end
        end
      end
    end
  end

  defp trading_symbols do
    let [
      symbol <- non_empty_string(),
      base_asset <- non_empty_string(),
      quote_asset <- non_empty_string(),
      base_asset_precision <- pos_integer(),
      quote_asset_precision <- pos_integer(),
      base_asset_increment <- pos_decimal(),
      quote_asset_increment <- pos_decimal(),
      min_notional <- pos_decimal()
    ] do
      let symbols <-
            non_empty(
              list(%Symbol{
                symbol: symbol,
                baseAsset: base_asset,
                quoteAsset: quote_asset,
                baseAssetPrecision: base_asset_precision,
                quoteAssetPrecision: quote_asset_precision,
                baseAssetIncrement: base_asset_increment,
                quoteAssetIncrement: quote_asset_increment,
                minNotional: min_notional
              })
            ) do
        symbols
      end
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

  defp positive_integer do
    let integer <- non_neg_integer() do
      integer
    end
  end

  defp pos_decimal do
    let float <- float(0.000001, :inf) do
      Decimal.from_float(float)
    end
  end
end
