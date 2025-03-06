defmodule ReservedSymbols.Impl do
  @moduledoc """
  ReservedSymbols implementation
  """

  alias Balance.Exchange

  use Agent
  require Decimal

  def new do
    %{}
  end

  def get_reserved(state) do
    Map.keys(state)
  end

  def reserve_list!(state, symbols) do
    Enum.reduce(symbols, state, fn symbol, acc ->
      reserve!(acc, symbol)
    end)
  end

  defp reserve!(state, symbol) do
    Map.has_key?(state, symbol) && raise "Symbol #{symbol} is already reserved"
    Map.put_new(state, symbol, true)
  end

  def release_list!(state, symbols) do
    Enum.reduce(symbols, state, fn symbol, acc ->
      release!(acc, symbol)
    end)
  end

  defp release!(state, symbol) do
    {_, new_state} = Map.pop!(state, symbol)
    new_state
  end
end
