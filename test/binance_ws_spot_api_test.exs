defmodule BinanceWSSpotApiTest do
  @moduledoc "Tests for BinanceWSSpotApi"
  use ExUnit.Case

  test "new_order_request/2 constructs a new order request" do
    api_key = "vmPUZE6mv9SD5VNHk4HlWFsOr6aKE2zvsw0MuIgwCIPy6utIco14y7Ju91duEh8A"
    api_secret = "NhqPtmdSJYdKjVHjA7PZj4Mge3R5YNiP1e3UZjInClVN65XAbvqqM6A7H5fATj0j"

    trading_symbol = {"BTCUSDT", :long}
    quantity = 1.0

    result = BinanceWSSpotApi.market_order_request(trading_symbol, quantity, api_key, api_secret)

    result_map = Poison.decode!(result)

    assert %{
             "id" => "market_order_id",
             "method" => "order.place",
             "params" => %{
               "apiKey" => "vmPUZE6mv9SD5VNHk4HlWFsOr6aKE2zvsw0MuIgwCIPy6utIco14y7Ju91duEh8A",
               "quantity" => 1.0,
               "side" => "BUY",
               "symbol" => "BTCUSDT",
               "timestamp" => _,
               "type" => "MARKET",
               "signature" => _
             }
           } = result_map
  end

  test "signature correct" do
    expected_signature = "cc15477742bd704c29492d96c7ead9414dfd8e0ec4a00f947bb5bb454ddbd08a"
    api_secret = "NhqPtmdSJYdKjVHjA7PZj4Mge3R5YNiP1e3UZjInClVN65XAbvqqM6A7H5fATj0j"

    params = %{
      newOrderRespType: "ACK",
      price: "52000.00",
      quantity: "0.01000000",
      recvWindow: 100,
      side: "SELL",
      symbol: "BTCUSDT",
      timeInForce: "GTC",
      timestamp: "1645423376532",
      type: "LIMIT",
      apiKey: "vmPUZE6mv9SD5VNHk4HlWFsOr6aKE2zvsw0MuIgwCIPy6utIco14y7Ju91duEh8A"
    }

    assert BinanceWSSpotApi.calculate_signature(params, api_secret) == expected_signature
  end

  test "message parsed correctly" do
    msg =
      Poison.encode!(%{
        id: "market_order_id",
        status: 200,
        result: %{
          symbol: "BTCUSDT",
          orderId: 1,
          orderListId: -1,
          clientOrderId: "asd",
          transactTime: 1234
        },
        ratelimits: [
          %{
            rateLimitType: "ORDERS",
            interval: "SECOND",
            intervalNum: 10,
            limit: 50,
            count: 1
          },
          %{
            rateLimitType: "ORDERS",
            interval: "SECOND",
            intervalNum: 10,
            limit: 50,
            count: 1
          },
          %{
            rateLimitType: "REQUEST_WEIGHT",
            interval: "SECOND",
            intervalNum: 10,
            limit: 50,
            count: 1
          }
        ]
      })

    assert BinanceWSSpotApi.parse_message(msg) == {:order_ack}
  end

  test "unknown msg results in unknown" do
    assert {:unknown, _} = BinanceWSSpotApi.parse_message(~c'{"unknown":"1"}')
  end

  test "error msg results in error" do
    assert {:error, _} = BinanceWSSpotApi.parse_message("error")
  end
end
