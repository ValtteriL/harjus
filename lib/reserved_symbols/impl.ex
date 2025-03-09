defmodule ReservedSymbols.Impl do
  @moduledoc """
  ReservedSymbols implementation
  """

  use Agent
  require Decimal

  alias Types.TradingSymbol

  @spec new() :: any()
  def new do
    %{}
  end

  @spec get_reserved(state :: any()) :: list()
  def get_reserved(state) do
    Map.keys(state)
  end

  @spec reserve_list!(state :: any(), symbols :: list(TradingSymbol.t())) :: :ok
  def reserve_list!(state, symbols = [%TradingSymbol{} | _]) do
    Enum.reduce(symbols, state, fn symbol, acc ->
      reserve!(acc, symbol)
    end)
  end

  defp reserve!(state, symbol = %TradingSymbol{}) do
    key = {symbol.symbol, symbol.position}
    Map.has_key?(state, key) && raise "Symbol #{inspect(key)} is already reserved"
    Map.put_new(state, key, true)
  end

  @spec release_list!(state :: any(), symbols :: list(TradingSymbol.t())) :: :ok
  def release_list!(state, symbols = [%TradingSymbol{} | _]) do
    Enum.reduce(symbols, state, fn symbol, acc ->
      release!(acc, symbol)
    end)
  end

  defp release!(state, symbol = %TradingSymbol{}) do
    key = {symbol.symbol, symbol.position}
    {_, new_state} = Map.pop!(state, key)
    new_state
  end
end
