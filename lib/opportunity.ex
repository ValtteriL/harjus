defmodule Opportunity do
  @moduledoc """
  Functions for calculating arbitrage opportunities.
  """

  @spec profit(
          trading_path :: [{charlist(), :long | :short}],
          price_quantity_map :: %{
            {charlist(), :long | :short} => %{price: float(), quantity: float()}
          }
        ) :: float()
  @doc """
  Calculate triangular arbitrage profit percentage for a trading path given symbol prices
  """
  def profit(trading_path, price_quantity_map) do
    trading_path
    |> Enum.map(fn symbol -> Map.get(price_quantity_map, symbol).price end)
    |> Enum.reduce(1, fn price, acc -> acc / price end)
    |> Kernel.-(1)
  end

  @spec capacity(
          trading_path :: [{charlist(), :long | :short}],
          price_quantity_map :: %{
            {charlist(), :long | :short} => %{price: float(), quantity: float()}
          },
          profit :: float()
        ) :: float()
  @doc """
  Calculate triangular arbitrage capacity for a trading path given symbol offer quantities and profit percentage

  The capacity is the amount of the first trading pair currency that can be traded in the path.
  Taking into accound only best ask prices and quantities.
  """
  def capacity(trading_path, price_quantity_map, profit) do
    first_symbol_qty = Map.get(price_quantity_map, Enum.at(trading_path, 0)).quantity

    trading_path
    |> Enum.map(fn symbol -> Map.get(price_quantity_map, symbol) end)
    # skip first symbol
    |> Enum.drop(1)
    |> Enum.reduce(first_symbol_qty, fn price_quantity, acc ->
      min(acc / price_quantity.price, price_quantity.quantity)
    end)
    |> Kernel./(1 + profit)
  end
end
