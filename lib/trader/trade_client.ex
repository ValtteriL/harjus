defmodule Trader.TradeClient do
  @moduledoc """
  Client for placing trades
  """
  alias Trader.TradeClient.Impl

  defdelegate new(), to: Impl
  defdelegate limit_order(trading_symbol, quantity, price), to: Impl
end
