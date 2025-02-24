defmodule Trader.Error.OrderCanceledError do
  @moduledoc """
  Type for normal error
  """
  defexception message: "Order was canceled"
end
