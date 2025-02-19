defmodule OpportunityWatcher.Opportunity.Impl do
  @moduledoc """
  Functions for calculating arbitrage opportunities.
  """

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
    profit(trading_path, price_quantity_map, commission_percentage, Decimal.new(1))
  end

  defp profit(
         [symbol = %TradingSymbol{} | rest],
         price_quantity_map = %{},
         commission_percentage,
         acc
       ) do
    price = elem(Map.get(price_quantity_map, symbol), 0)

    if Decimal.eq?(price, 0) do
      price
    else
      new_acc =
        Decimal.div(
          Decimal.mult(
            acc,
            Decimal.sub(1, commission_percentage)
          ),
          price
        )

      profit(rest, price_quantity_map, commission_percentage, new_acc)
    end
  end

  defp profit([], _price_quantity_map, _commission_percentage, acc), do: Decimal.sub(acc, 1)

  @spec capacity(
          trading_path :: trading_path(),
          price_quantity_map :: %{
            TradingSymbol.t() => price_qty_tuple()
          }
        ) :: Decimal.t()
  def capacity(trading_path = [firstsymbol = %TradingSymbol{} | rest], price_quantity_map = %{}) do
    {_first_symbol_price, first_symbol_qty} = Map.get(price_quantity_map, firstsymbol)

    prices = Enum.map(trading_path, fn symbol -> elem(Map.get(price_quantity_map, symbol), 0) end)

    # if any of the prices are 0, return 0
    if Enum.any?(prices, fn price -> Decimal.eq?(price, 0) end) do
      Decimal.new(0)
    else
      rest
      |> Enum.map(fn symbol -> Map.get(price_quantity_map, symbol) end)
      |> Enum.reduce(first_symbol_qty, fn {price, quantity}, acc ->
        Decimal.min(Decimal.div(acc, price), quantity)
      end)
      |> Decimal.div(Decimal.add(1, profit_without_commission(trading_path, price_quantity_map)))
    end
  end

  defp profit_without_commission(trading_path, price_quantity_map) do
    trading_path
    |> Enum.map(fn symbol -> elem(Map.get(price_quantity_map, symbol), 0) end)
    |> Enum.reduce(1, fn price, acc -> Decimal.div(acc, price) end)
    |> Decimal.sub(1)
  end
end
