defmodule Pipeline.PricingTable do
  @moduledoc """
  Table for storing prices
  """

  alias Pipeline.PricingTable.Impl

  @doc """
  Create new pricing table
  """
  defdelegate new(trading_paths), to: Impl

  @doc """
  Update pricing table with new price update and get affected paths
  """
  defdelegate update_get_affected(pricing_table, update), to: Impl
end
