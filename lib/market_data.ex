defmodule MarketData do
  @moduledoc """
  Market data module

  This module is responsible for fetching market data from the exchange
  """

  alias MarketData.Impl
  alias Types.TradingSymbol

  @doc """
  Create a new instance of the market data
  """
  @spec new() :: any()
  def new do
    Impl.new()
  end

  @doc """
  Get trading paths from the market data that start with the given symbols, up to the given depth
  """
  @spec trading_paths(data :: any(), starting_symbols :: [String.t()], depth :: integer()) ::
          {trading_paths :: [[TradingSymbol.t()]], symbol_list :: [charlist()]}
  def trading_paths(state, starting_symbols, depth) do
    Impl.trading_paths(state, starting_symbols, depth)
  end

  @doc """
  Get the relative values of all assets in the market data
  """
  @spec relative_values(data :: any()) :: %{symbol: String.t(), value: float()}
  def relative_values(data) do
    Impl.relative_values(data)
  end
end
