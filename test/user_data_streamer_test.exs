defmodule UserDataStreamerTest do
  use ExUnit.Case
  doctest UserDataStreamer

  test "start_link/1 starts the WebSocket connection and subscribes to user data stream" do
    {:ok, pid} = UserDataStreamer.start_link(%{api_key: "test_key", api_secret: "test_secret", is_prod: false})
    assert Process.alive?(pid)
  end

  test "handle_frame/2 logs received user data events" do
    {:ok, pid} = UserDataStreamer.start_link(%{api_key: "test_key", api_secret: "test_secret", is_prod: false})
    msg = Poison.encode!(%{e: "event_type", some_key: "some_value"})
    send(pid, {:text, msg})
    assert_receive {:info, "Received user data event: %{e: \"event_type\", some_key: \"some_value\"}"}
  end

  test "handle_ping/2 responds to ping messages" do
    {:ok, pid} = UserDataStreamer.start_link(%{api_key: "test_key", api_secret: "test_secret", is_prod: false})
    send(pid, {:ping, "ping_id"})
    assert_receive {:pong, "ping_id"}
  end

  test "subscribe/1 sends a subscription message" do
    {:ok, pid} = UserDataStreamer.start_link(%{api_key: "test_key", api_secret: "test_secret", is_prod: false})
    UserDataStreamer.subscribe(pid)
    assert_receive {:text, Poison.encode!(%{method: "SUBSCRIBE", params: ["!userData"], id: "user_data_sub"})}
  end
end
