defmodule WSSpotApiTest do
  use ExUnit.Case

  test "new_order_request/2 constructs a new order request" do
    symbol = "BTCUSDT"
    quantity = 1.0

    expected_request = %{
      method: "ORDER",
      params: %{
        symbol: symbol,
        quantity: quantity
      }
    }

    assert WSSpotApi.new_order_request(symbol, quantity) == expected_request
  end

  test "get_balance_request/1 constructs a get balance request" do
    asset = "BTC"

    expected_request = %{
      method: "GET_BALANCE",
      params: %{
        asset: asset
      }
    }

    assert WSSpotApi.get_balance_request(asset) == expected_request
  end
end
