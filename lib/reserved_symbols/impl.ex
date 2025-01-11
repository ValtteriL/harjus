defmodule ReservedSymbols.Impl do
  @moduledoc """
  Implementation of the ReservedSymbols behaviour
  """

  use Agent

  def new do
    MapSet.new()
  end

  def reserved?(state, symbol) do
    MapSet.member?(state, symbol)
  end

  def reserve(state, symbol) do
    MapSet.put(state, symbol)
  end

  def release(state, symbol) do
    MapSet.delete(state, symbol)
  end
end
