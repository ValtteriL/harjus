defmodule Balance.Exchange do
  @moduledoc """
  Exchange behavior
  """

  @doc """
  Get account balances
  """

  @callback get_balances() :: %{String.t() => Decimal.t()}
end
