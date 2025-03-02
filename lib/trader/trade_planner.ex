defmodule Trader.TradePlanner do
  @moduledoc """
  Planner for trading
  """
  alias Trader.TradePlanner.Impl

  defdelegate plan_execution(opportunity, budget), to: Impl
end
