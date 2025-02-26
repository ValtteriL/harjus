defmodule OpportunityWatcher.Opportunity.Impl do
  @moduledoc """
  Functions for calculating arbitrage opportunities.
  """

  alias Types.PlannedTrade
  alias Types.TradingSymbol

  require Decimal

  @type trading_path() :: [TradingSymbol.t()]
  @type price_qty_tuple() :: {price :: Decimal.t(), quantity :: Decimal.t()}

  @spec profit(
          trading_path :: trading_path(),
          price_quantity_map :: %{
            TradingSymbol.t() => price_qty_tuple()
          },
          commissing_percentage :: Decimal.t()
        ) :: Decimal.t()
  def profit(
        trading_path = [%TradingSymbol{} | _],
        price_quantity_map = %{},
        commission_percentage
      )
      when Decimal.is_decimal(commission_percentage) do
    prices = Enum.map(trading_path, fn symbol -> elem(Map.get(price_quantity_map, symbol), 0) end)

    # if any of the prices are 0, return 0
    if Enum.any?(prices, fn price -> Decimal.eq?(price, 0) end) do
      Decimal.new(0)
    else
      trading_path
      |> Enum.map(fn symbol -> elem(Map.get(price_quantity_map, symbol), 0) end)
      |> Enum.reduce(Decimal.new(1), fn price, acc ->
        Decimal.div(
          Decimal.mult(
            acc,
            Decimal.sub(1, commission_percentage)
          ),
          price
        )
      end)
      |> Decimal.sub(1)
    end
  end

  @spec capacity(
          trading_path :: trading_path(),
          price_quantity_map :: %{
            TradingSymbol.t() => price_qty_tuple()
          }
        ) :: Decimal.t()
  def capacity(trading_path = [%TradingSymbol{} | _], price_quantity_map = %{}) do
    prices = Enum.map(trading_path, fn symbol -> elem(Map.get(price_quantity_map, symbol), 0) end)

    # if any of the prices are 0, return 0
    if(Enum.any?(prices, fn price -> Decimal.eq?(price, 0) end),
      do: Decimal.new(0),
      else: calculate_capacity(trading_path, price_quantity_map)
    )
  end

  defp calculate_capacity(
         trading_path = [firstsymbol = %TradingSymbol{} | _],
         price_quantity_map
       ) do
    {_first_symbol_price, first_symbol_qty} = Map.get(price_quantity_map, firstsymbol)

    Enum.reduce(trading_path, first_symbol_qty, fn symbol, acc ->
      {price, quantity} = Map.get(price_quantity_map, symbol)

      lowest = Decimal.min(Decimal.div(acc, price), quantity)

      # if lowest * price lt min_notional, return 0. else return lowest

      notional =
        case symbol.position do
          :long -> Decimal.mult(lowest, price)
          # estimate price of long as 1/(price * 1.05)
          :short -> Decimal.div(lowest, price |> Decimal.mult("1.05"))
        end

      if(Decimal.lt?(notional, firstsymbol.min_notional), do: Decimal.new(0), else: lowest)
    end)
    |> Decimal.div(Decimal.add(1, profit_without_commission(trading_path, price_quantity_map)))
  end

  defp profit_without_commission(trading_path, price_quantity_map) do
    Enum.map(trading_path, fn symbol -> elem(Map.get(price_quantity_map, symbol), 0) end)
    |> Enum.reduce(1, fn price, acc -> Decimal.div(acc, price) end)
    |> Decimal.sub(1)
  end

  @spec plan_trades(
          trading_path :: trading_path(),
          capacity :: Decimal.t(),
          price_quantity_map :: %{
            TradingSymbol.t() => price_qty_tuple()
          }
        ) :: [PlannedTrade.t()]
  def plan_trades(trading_path = [%TradingSymbol{} | _], capacity, price_quantity_map = %{}) do
    trading_path
    |> Enum.map_reduce(capacity, fn symbol, acc ->
      {order_price, _} = Map.get(price_quantity_map, symbol)
      order_qty = order_qty_for_budget(acc, order_price, symbol)

      {
        %PlannedTrade{
          trading_symbol: symbol,
          order_price: order_price,
          order_qty: order_qty
        },
        order_qty
      }
    end)
    |> elem(0)
  end

  defp order_qty_for_budget(budget, price, trading_symbol) do
    Decimal.div(budget, price)
    |> Decimal.div_int(trading_symbol.base_asset_increment)
    |> Decimal.mult(trading_symbol.base_asset_increment)
  end
end
