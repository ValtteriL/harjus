defmodule Trader.Balance do
  @moduledoc """
  Balance behavior

  Used to mock the balance module
  """

  @callback reserve!(String.t(), Decimal.t()) :: :ok

  def reserve!(asset, amount), do: impl().reserve!(asset, amount)

  defp impl, do: Application.get_env(:harjus, :balance, Balance)
end
