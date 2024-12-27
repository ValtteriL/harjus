defmodule WSSpotApiClientTest do
  use ExUnit.Case

  test "init/1 establishes an authenticated websocket session" do
    {:ok, pid} = WSSpotApiClient.start_link("api_key", "api_secret")
    assert Process.alive?(pid)
  end

  test "make_order/2 makes an order" do
    {:ok, pid} = WSSpotApiClient.start_link("api_key", "api_secret")
    assert {:ok, :order_response} = WSSpotApiClient.make_order(%{symbol: "BTCUSDT", side: "BUY", type: "LIMIT", quantity: 1, price: 50000})
  end

  test "get_balances/1 gets balances on spot wallet" do
    {:ok, pid} = WSSpotApiClient.start_link("api_key", "api_secret")
    assert {:ok, :balances} = WSSpotApiClient.get_balances()
  end

  test "handle_ping/2 replies to pings from the Binance server" do
    {:ok, pid} = WSSpotApiClient.start_link("api_key", "api_secret")
    send(pid, {:ping, :ping_id})
    assert Process.alive?(pid)
  end
end
