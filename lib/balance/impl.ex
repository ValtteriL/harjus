defmodule Balance.Impl do
  @moduledoc """
  Implementation of the balance process
  """

  alias Balance.Exchange

  use Agent
  require Decimal

  def new do
    Exchange.get_balances()
  end

  @spec get(state :: map(), asset :: String.t()) :: Decimal.t()
  def get(state = %{}, asset = "" <> _) do
    Map.get(state, asset, Decimal.new(0))
  end

  @spec update(state :: map(), asset :: String.t(), amount :: Decimal.t()) :: map()
  def update(state = %{}, asset = "" <> _, amount) when Decimal.is_decimal(amount) do
    Map.update(state, asset, amount, &Decimal.add(&1, amount))
  end

  @spec reserve_upto(
          state :: map(),
          asset :: String.t(),
          amount :: Decimal.t(),
          increment :: Decimal.t(),
          precision :: integer()
        ) ::
          {Decimal.t(), map()}
  def reserve_upto(state = %{}, asset = "" <> _, amount, increment, precision)
      when Decimal.is_decimal(amount) and Decimal.is_decimal(increment) and is_integer(precision) do
    current_balance = get(state, asset)
    reserved_amount = max_reserved_amount(current_balance, amount, increment, precision)

    {reserved_amount, update(state, asset, Decimal.negate(reserved_amount))}
  end

  defp max_reserved_amount(current_balance, amount, increment, precision) do
    max =
      case Decimal.lte?(current_balance, amount) do
        true -> current_balance
        false -> amount
      end

    Decimal.div_int(max, increment) |> Decimal.mult(increment) |> Decimal.round(precision)
  end
end
