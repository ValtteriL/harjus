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

  def get_balances(state) do
    state
  end

  def decrement(state, asset, amount) do
    Map.update!(state, asset, fn current_balance ->
      Decimal.sub(current_balance, amount)
    end)
  end

  def increment_map(state, asset_map) do
    Enum.reduce(asset_map, state, fn {asset, amount}, acc ->
      increment(acc, asset, amount)
    end)
  end

  defp increment(state, asset, amount) do
    Map.update(state, asset, Decimal.new(0), fn current_balance ->
      Decimal.add(current_balance, amount)
    end)
  end
end
