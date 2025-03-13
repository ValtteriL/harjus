defmodule MarketData.Impl do
  @moduledoc """
  Market data implementation
  """

  alias MarketData.Arbmapper
  alias MarketData.AssetComparer
  alias MarketData.Exchange

  require Logger

  def new do
    %{
      symbols: Exchange.get_symbols(),
      symbol_prices: Exchange.get_symbol_prices()
    }
  end

  def trading_paths(%{symbols: symbols}, starting_symbols, depth, blacklisted_starting_symbols)
      when is_integer(depth) and is_list(starting_symbols) do
    # discover trading paths

    Arbmapper.generate_trading_paths(
      symbols,
      starting_symbols: starting_symbols,
      depth: depth,
      blacklisted_starting_symbols: blacklisted_starting_symbols
    )
  end

  def relative_values(
        %{symbols: symbols, symbol_prices: symbol_prices},
        comparison_asset = "" <> _
      ) do
    AssetComparer.calculate_relative_values(
      symbols,
      symbol_prices,
      comparison_asset
    )
  end
end
