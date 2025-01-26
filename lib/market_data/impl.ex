defmodule MarketData.Impl do
  @moduledoc """
  Market data implementation
  """

  alias MarketData.Arbmapper
  alias MarketData.AssetComparer
  alias MarketData.Exchange
  alias Types.TradingSymbol

  require Logger

  def new do
    %{
      symbols: Exchange.get_symbols(),
      symbol_prices: Exchange.get_symbol_prices()
    }
  end

  def trading_paths(%{symbols: symbols}, starting_symbols = ["" <> _ | _], depth)
      when is_integer(depth) do
    # discover trading paths

    Arbmapper.generate_trading_paths(
      symbols,
      starting_symbols: starting_symbols,
      depth: depth
    )
  end

  def relative_values(%{symbols: symbols, symbol_prices: symbol_prices}) do
    AssetComparer.calculate_relative_values(
      symbols,
      symbol_prices,
      "BTC"
    )
  end
end
