defmodule OpportunityWatcher.Opportunity do
  @moduledoc """
  Functions for calculating arbitrage opportunities.
  """

  alias Types.TradingSymbol

  @type trading_path() :: [TradingSymbol.t()]
  @type price_qty_tuple() :: {price :: float(), quantity :: float()}

  @spec profit(
          trading_path :: trading_path(),
          price_quantity_map :: %{
            TradingSymbol.t() => price_qty_tuple()
          }
        ) :: float()
  @doc """
  Calculate triangular arbitrage profit percentage for a trading path given symbol prices
  """
  def profit(trading_path, price_quantity_map) do
    trading_path
    |> Enum.map(fn symbol -> elem(Map.get(price_quantity_map, symbol), 0) end)
    |> Enum.reduce(1, fn price, acc -> acc / price end)
    |> Kernel.-(1)
  end

  @spec capacity(
          trading_path :: trading_path(),
          price_quantity_map :: %{
            TradingSymbol.t() => price_qty_tuple()
          },
          profit :: float()
        ) :: float()
  @doc """
  Calculate triangular arbitrage capacity for a trading path given symbol offer quantities and profit percentage

  The capacity is the amount of the first trading pair currency that can be traded in the path.
  Taking into accound only best ask prices and quantities.
  """
  def capacity(trading_path, price_quantity_map, profit) do
    first_symbol_qty = elem(Map.get(price_quantity_map, Enum.at(trading_path, 0)), 1)

    trading_path
    |> Enum.map(fn symbol -> Map.get(price_quantity_map, symbol) end)
    # skip first symbol
    |> Enum.drop(1)
    |> Enum.reduce(first_symbol_qty, fn price_quantity, acc ->
      min(acc / elem(price_quantity, 0), elem(price_quantity, 1))
    end)
    |> Kernel./(1 + profit)
  end
end
