defmodule AccountData do
  @moduledoc """
  This module is responsible for fetching account data
  """

  alias AccountData.Impl

  @doc """
  Get account balances
  """
  @spec get_balances() :: %{String.t() => float()}
  def get_balances do
    Impl.get_balances()
  end
end
