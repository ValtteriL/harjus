defmodule Pipeline.Impl do
  @moduledoc """
  Implementation of the pipeline
  """

  alias Pipeline.PricingTable

  @spec new(
          trading_paths :: [TradingSymbol.t()],
          commission :: Decimal.t(),
          relative_asset_values :: any()
        ) :: any()
  def new(trading_paths, commission, relative_asset_values) do
    %{
      pricing_table: PricingTable.new(trading_paths),
      commission: commission,
      relative_asset_values: relative_asset_values
    }
  end

  @spec price_update(state :: any(), update :: tuple()) :: any()
  def price_update(
        %{
          pricing_table: pricing_table,
          commission: commission,
          relative_asset_values: relative_asset_values
        },
        update = {_symbol, _ask_price, _ask_qty, _bid_price, _bid_qty}
      ) do
    :ok
  end
end
