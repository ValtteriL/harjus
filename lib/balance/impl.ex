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
end
