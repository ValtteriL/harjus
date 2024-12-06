defmodule Opportunity do
  @moduledoc """
  Functions for calculating arbitrage opportunities.
  """

  @doc """
  Calculate triangular arbitrage profit and capacity in first trading pair currency for trading path given prices and available quantities

  The idea is that the maximum capacity is the quantity of the best_bid in the first trading pair currency.
  """
  @spec triangular_arbitrage([charlist()], %{
          charlist() => %{best_ask: float(), quantity: float()}
        }) :: %{
          # profit in percent (not multiplied by 100)
          profit: float(),
          # capacity of opportunity
          capacity: float()
        }
  def triangular_arbitrage(path, price_quantity_map) do
    # calculate profit
    profit =
      path
      |> Enum.map(fn symbol -> Map.get(price_quantity_map, symbol).best_ask end)
      |> Enum.reduce(1, fn price, acc -> acc / price end)
      |> Kernel.-(1)

    first_symbol_price = Map.get(price_quantity_map, Enum.at(path, 0)).best_ask
    # convert all quantities to first trading pair currency, multiply by quantity, take minimum
    capacity =
      path
      |> Enum.map(fn symbol -> Map.get(price_quantity_map, symbol) end)
      |> Enum.map_reduce(first_symbol_price, fn price_quantity, acc ->
        {price_quantity.best_ask / acc * price_quantity.quantity,
         price_quantity.best_ask / acc * price_quantity.quantity}
      end)
      # drop accumulator
      |> elem(0)
      |> Enum.min()

    %{profit: profit, capacity: capacity}
  end
end
