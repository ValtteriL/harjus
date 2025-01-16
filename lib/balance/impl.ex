defmodule Balance.Impl do
  @moduledoc """
  Implementation of the balance process
  """

  use Agent

  def new(balance_map) do
    balance_map
  end

  def get(state, asset) do
    Map.get(state, asset, 0)
  end

  def update(state, asset, amount) do
    Map.update(state, asset, amount, &(&1 + amount))
  end

  def reserve_upto(state, asset, amount) do
    current_balance = get(state, asset)

    cond do
      current_balance >= amount ->
        {amount, update(state, asset, -amount)}

      current_balance < amount ->
        {current_balance, update(state, asset, -current_balance)}
    end
  end
end
