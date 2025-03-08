defmodule Pipeline.PricingTable do
  @moduledoc """
  Table for storing prices
  """

  alias Pipeline.PricingTable.Impl

  @doc """
  Create new pricing table
  """
  @spec new([TradingSymbol.t()]) :: any()
  defdelegate new(trading_paths), to: Impl

  @doc """
  Update pricing table with new price update and get affected paths
  """
  @spec update_get_affected(any(), tuple()) :: {any(), list()}
  defdelegate update_get_affected(pricing_table, update), to: Impl
end
