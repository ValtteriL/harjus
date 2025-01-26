defmodule MarketDataTest do
  @moduledoc "Tests for MarketData"

  alias Types.TradingSymbol

  use ExUnit.Case
  doctest MarketData
  use PropCheck

  property "generates correct trading paths and symbols", [:verbose] do
    forall [trading_symbols, starting_symbols, depth] <- [
             trading_symbols(),
             non_empty(list(non_empty_string())),
             positive_integer()
           ] do
      md = MarketData.new()
      {paths, symbols} = MarketData.trading_paths(md, starting_symbols, depth)
      relative_prices = MarketData.relative_values(md)

      # test types
      assert is_list(paths)
      assert is_list(symbols)
      assert is_map(relative_prices)

      input_symbols = trading_symbols |> Enum.map(fn x -> x[:symbol] end) |> Enum.uniq()

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

      # trading paths must be of length depth or less if defined
      assert Enum.all?(paths, fn x -> length(x) <= depth end)

      # trading path can contain a single trading symbol only once
      assert Enum.all?(paths, fn x -> Enum.uniq(x) == x end)

      # output map must include all symbols as keys
      Enum.each(symbols, fn x ->
        assert Map.has_key?(relative_prices, x[:baseAsset])
        assert Map.has_key?(relative_prices, x[:quoteAsset])
      end)

      true
    end
  end

  ## Generators ##

  defp trading_symbols do
    let symbol <- non_empty_string() do
      let base_asset <- non_empty_string() do
        let quote_asset <- non_empty_string() do
          let a <-
                non_empty(list(%{symbol: symbol, baseAsset: base_asset, quoteAsset: quote_asset})) do
            a
          end
        end
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
end
