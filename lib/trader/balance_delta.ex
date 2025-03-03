defmodule Trader.BalanceDelta do
  @moduledoc """
  Module for calculating balance deltas
  """

  alias Trader.BalanceDelta.Impl

  defdelegate update_balance_delta(delta, trading_symbol, trade_report), to: Impl
end
