defmodule MarketData.Impl do
  @moduledoc """
  Market data implementation
  """

  @exchange Application.compile_env(:harjus, :marketdata_exchange)

  alias MarketData.Arbmapper
  alias MarketData.AssetComparer

  require Logger

  def new do
    %{
      symbols: @exchange.get_symbols(),
      symbol_prices: @exchange.get_symbol_prices()
    }
  end

  def trading_paths(state, starting_symbols, depth) do
    # discover trading paths

    Arbmapper.generate_trading_paths(
      state.symbols,
      starting_symbols: starting_symbols,
      depth: depth
    )
  end

  def relative_values(state) do
    AssetComparer.calculate_relative_values(
      state.symbols,
      state.symbol_prices,
      "BTC"
    )
  end
end
