defmodule WSSpotApi do
  def new_order_request(symbol, quantity) do
    %{
      method: "ORDER",
      params: %{
        symbol: symbol,
        quantity: quantity
      }
    }
  end

  def get_balance_request(asset) do
    %{
      method: "GET_BALANCE",
      params: %{
        asset: asset
      }
    }
  end
end
