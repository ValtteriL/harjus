defmodule Pipeline.PricingTable do
  @moduledoc """
  Table for storing prices
  """

  alias Pipeline.PricingTable.Impl

  defdelegate new(trading_paths), to: Impl
  defdelegate update_get_affected(pricing_table, update), to: Impl
end
