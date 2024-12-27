defmodule WSSpotApiClientTest do
  use ExUnit.Case

  test "init/1 establishes an authenticated websocket session" do
    api_key = "test_api_key"
    api_secret = "test_api_secret"

    {:ok, pid} = WSSpotApiClient.start_link(api_key, api_secret)

    assert Process.alive?(pid)
  end

  test "make_order/2 makes an order using WSSpotApi.new_order_request/2" do
    api_key = "test_api_key"
    api_secret = "test_api_secret"
    symbol = "BTCUSDT"
    quantity = 1.0

    {:ok, pid} = WSSpotApiClient.start_link(api_key, api_secret)

    assert WSSpotApiClient.make_order(symbol, quantity) == :ok
  end

  test "get_balances/1 gets balances on spot wallet using WSSpotApi.get_balance_request/1" do
    api_key = "test_api_key"
    api_secret = "test_api_secret"
    asset = "BTC"

    {:ok, pid} = WSSpotApiClient.start_link(api_key, api_secret)

    assert WSSpotApiClient.get_balances(asset) == :ok
  end

  test "handle_ping/2 replies to pings from the Binance server" do
    api_key = "test_api_key"
    api_secret = "test_api_secret"

    {:ok, pid} = WSSpotApiClient.start_link(api_key, api_secret)

    send(pid, {:ping, "ping_id"})

    assert_receive {:pong, "ping_id"}
  end
end
