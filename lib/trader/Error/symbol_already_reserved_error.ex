defmodule Trader.Error.SymbolAlreadyReservedError do
  @moduledoc """
  Type for normal error
  """
  defexception message: "Trading symbol already reserved"
end
