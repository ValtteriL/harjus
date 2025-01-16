defmodule ReservedSymbols.Impl do
  @moduledoc """
  Implementation of the ReservedSymbols behaviour
  """

  use Agent

  def new do
    MapSet.new()
  end

  def reserved?(state, symbols) do
    Enum.any?(symbols, fn symbol -> MapSet.member?(state, symbol) end)
  end

  def reserve(state, symbols) do
    case reserved?(state, symbols) do
      true -> {:error, state}
      false -> {:ok, symbols |> Enum.reduce(state, fn symbol, acc -> MapSet.put(acc, symbol) end)}
    end
  end

  def release(state, symbols) do
    Enum.reduce(symbols, state, fn symbol, acc -> MapSet.delete(acc, symbol) end)
  end
end
