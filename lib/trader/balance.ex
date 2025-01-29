defmodule Trader.Balance do
  @moduledoc """
  Balance behavior

  Used to mock the balance module
  """

  @callback get(String.t()) :: Decimal.t()
  @callback update(String.t(), Decimal.t()) :: :ok
  @callback reserve_upto(String.t(), Decimal.t()) :: Decimal.t()

  def get(asset), do: impl().get(asset)
  def update(asset, amount), do: impl().update(asset, amount)
  def reserve_upto(asset, amount), do: impl().reserve_upto(asset, amount)
  defp impl, do: Application.get_env(:harjus, :balance, Balance)
end
