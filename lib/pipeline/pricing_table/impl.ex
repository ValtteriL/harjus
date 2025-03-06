defmodule Pipeline.PricingTable.Impl do
  @moduledoc """
  Implementation of the pricing table
  """
  alias Types.PriceUpdate

  @spec new(trading_paths :: [TradingSymbol.t()]) :: any()
  def new(trading_paths) do
    %{}
  end

  @spec update_get_affected(
          pricing_table :: any(),
          update :: PriceUpdate.t()
        ) :: any()
  def update_get_affected(pricing_table, update) do
    pricing_table
  end
end
