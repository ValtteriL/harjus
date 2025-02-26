defmodule OpportunityWatcher.Opportunity do
  @moduledoc """
  Functions for calculating arbitrage opportunities.
  """

  alias OpportunityWatcher.Opportunity.Impl
  alias Types.PlannedTrade
  alias Types.TradingSymbol

  @type trading_path() :: [TradingSymbol.t()]
  @type price_qty_tuple() :: {price :: Decimal.t(), quantity :: Decimal.t()}

  @spec profit(
          trading_path :: trading_path(),
          price_quantity_map :: %{
            TradingSymbol.t() => price_qty_tuple()
          },
          commissing_percentage :: Decimal.t()
        ) :: Decimal.t()
  @doc """
  Calculate triangular arbitrage profit percentage for a trading path given symbol prices
  """
  defdelegate profit(trading_path, price_quantity_map, commissing_percentage), to: Impl

  @spec capacity(
          trading_path :: trading_path(),
          price_quantity_map :: %{
            TradingSymbol.t() => price_qty_tuple()
          }
        ) :: Decimal.t()
  @doc """
  Calculate triangular arbitrage capacity for a trading path given symbol offer quantities and profit percentage

  The capacity is the amount of the first trading pair currency that can be traded in the path.
  Taking into accound only best ask prices and quantities.
  """
  defdelegate capacity(trading_path, price_quantity_map), to: Impl

  @spec plan_trades(
          trading_path :: trading_path(),
          capacity :: Decimal.t(),
          price_quantity_map :: %{
            TradingSymbol.t() => price_qty_tuple()
          }
        ) :: [PlannedTrade.t()]
  @doc """
  Plan trades for a trading path given symbol prices and quantities
  """
  defdelegate plan_trades(trading_path, capacity, price_quantity_map), to: Impl
end
