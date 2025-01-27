defmodule Balance.Impl do
  @moduledoc """
  Implementation of the balance process
  """

  @exchange Application.compile_env(:harjus, :balance_exchange)

  use Agent
  require Decimal

  def new do
    @exchange.get_balances()
  end

  @spec get(state :: map(), asset :: String.t()) :: Decimal.t()
  def get(state = %{}, asset = "" <> _) do
    Map.get(state, asset, Decimal.new(0))
  end

  @spec update(state :: map(), asset :: String.t(), amount :: Decimal.t()) :: map()
  def update(state = %{}, asset = "" <> _, amount) when Decimal.is_decimal(amount) do
    Map.update(state, asset, amount, &Decimal.add(&1, amount))
  end

  @spec reserve_upto(state :: map(), asset :: String.t(), amount :: Decimal.t()) ::
          {Decimal.t(), map()}
  def reserve_upto(state = %{}, asset = "" <> _, amount) when Decimal.is_decimal(amount) do
    current_balance = get(state, asset)

    cond do
      Decimal.gte?(current_balance, amount) ->
        {amount, update(state, asset, Decimal.negate(amount))}

      Decimal.lt?(current_balance, amount) ->
        {current_balance, update(state, asset, Decimal.negate(current_balance))}
    end
  end
end
