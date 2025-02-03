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

  @spec reserve_upto(state :: map(), asset :: String.t(), amount :: Decimal.t(), increment :: Decimal.t(), precision :: integer()) ::
          {Decimal.t(), map()}
  def reserve_upto(state = %{}, asset = "" <> _, amount, increment, precision) when Decimal.is_decimal(amount) do
    current_balance = get(state, asset)

    cond do
      Decimal.gte?(current_balance, amount) ->
        reserved_amount = round_to_increment(amount, increment, precision)
        {reserved_amount, update(state, asset, Decimal.negate(reserved_amount))}

      Decimal.lt?(current_balance, amount) ->
        reserved_amount = round_to_increment(current_balance, increment, precision)
        {reserved_amount, update(state, asset, Decimal.negate(reserved_amount))}
    end
  end

  defp round_to_increment(amount, increment, precision) do
    rounded_amount = Decimal.mult(Decimal.div(amount, increment) |> Decimal.round(0), increment)
    Decimal.round(rounded_amount, precision)
  end
end
