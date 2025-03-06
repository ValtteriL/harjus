defmodule Pipeline.TradePlanner do
  @moduledoc """
  Trade planner
  """

  alias Pipeline.TradePlanner.Impl

  defdelegate plan_execution(path, starting_asset_balance, relative_asset_values), to: Impl
end
