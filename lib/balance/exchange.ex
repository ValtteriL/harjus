defmodule Balance.Exchange do
  @moduledoc """
  Exchange behavior
  """

  @doc """
  Get account balances
  """

  @callback get_balances() :: %{String.t() => Decimal.t()}

  def get_balances, do: impl().get_balances()
  defp impl, do: Application.get_env(:harjus, :balance_exchange)
end
