defmodule Balance.Impl do
  @moduledoc """
  Implementation of the balance process
  """

  use Agent

  def new(balance_map) do
    balance_map
  end

  def get(state, asset) do
    Map.get(state, asset, Decimal.new(0))
  end

  def update(state, asset, amount) do
    Map.update(state, asset, amount, &Decimal.add(&1, amount))
  end

  def reserve_upto(state, asset, amount) do
    current_balance = get(state, asset)

    cond do
      Decimal.gte?(current_balance, amount) ->
        {amount, update(state, asset, Decimal.negate(amount))}

      Decimal.lt?(current_balance, amount) ->
        {current_balance, update(state, asset, Decimal.negate(current_balance))}
    end
  end
end
