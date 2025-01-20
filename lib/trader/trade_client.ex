defmodule Trader.TradeClient do
  @moduledoc """
  Client for placing trades
  """
  alias Trader.TradeClient.Impl

  defdelegate new(), to: Impl
  defdelegate market_order(trading_symbol, quantity), to: Impl
end
