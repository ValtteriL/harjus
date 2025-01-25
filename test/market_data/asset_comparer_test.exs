defmodule MarketData.AssetComparerTest do
  @moduledoc """
  Tests for the Balance module
  """
  alias MarketData.AssetComparer

  use ExUnit.Case
  doctest AssetComparer
  use PropCheck

  property "calculates relative values correctly", [:verbose] do
    forall {symbols, symbol_prices, comparison_asset} <- gen_symbols_prices_asset() do
      relative_prices =
        AssetComparer.calculate_relative_values(symbols, symbol_prices, comparison_asset)

      # output map must include all symbols as keys
      Enum.each(symbols, fn x ->
        assert Map.has_key?(relative_prices, x[:baseAsset])
        assert Map.has_key?(relative_prices, x[:quoteAsset])
      end)

      # comparison asset must have value 1.0
      assert relative_prices[comparison_asset] == Decimal.new("1.0")
    end
  end

  ## Generators ##

  defp gen_symbols_prices_asset do
    let symbols <- trading_symbols() do
      let price <- non_neg_float() do
        let symbol_prices <-
              symbols
              |> Enum.map(fn x -> x[:symbol] end)
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

  ## Unit tests ##

  test "calculates relative values correctly" do
    symbols = [
      %{symbol: "BTCUSDT", baseAsset: "BTC", quoteAsset: "USDT"},
      %{symbol: "ETHBTC", baseAsset: "ETH", quoteAsset: "BTC"},
      %{symbol: "ETHUSDT", baseAsset: "ETH", quoteAsset: "USDT"}
    ]

    symbol = "BTC"

    symbol_prices = %{
      "BTCUSDT" => Decimal.from_float(50_000.0),
      "ETHBTC" => Decimal.from_float(0.05),
      "ETHUSDT" => Decimal.from_float(2500.0)
    }

    expected = %{
      "BTC" => Decimal.from_float(1.0),
      "ETH" => Decimal.from_float(0.05),
      "USDT" => Decimal.from_float(0.00002)
    }

    assert AssetComparer.calculate_relative_values(symbols, symbol_prices, symbol) == expected
  end

  test "raises exception if comparison asset not found" do
    symbols = [
      %{symbol: "BTCUSDT", baseAsset: "BTC", quoteAsset: "USDT"}
    ]

    symbol_prices = %{
      "BTCUSDT" => Decimal.from_float(50_000.0)
    }

    assert_raise(MatchError, fn ->
      AssetComparer.calculate_relative_values(symbols, symbol_prices, "DOGE")
    end)
  end

  test "raises exception if symbols empty" do
    symbol_prices = %{
      "BTCUSDT" => Decimal.from_float(50_000.0)
    }

    assert_raise(FunctionClauseError, fn ->
      AssetComparer.calculate_relative_values([], symbol_prices, "DOGE")
    end)
  end
end
