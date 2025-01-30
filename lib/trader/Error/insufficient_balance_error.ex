defmodule Trader.Error.InsufficientBalanceError do
  @moduledoc """
  Type for normal error
  """
  defexception message: "No budget available to reserve"
end
