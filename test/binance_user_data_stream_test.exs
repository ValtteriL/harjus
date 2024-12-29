defmodule BinanceUserDataStreamTest do
  @moduledoc "Tests for BinanceUserDataStream"
  use ExUnit.Case
  doctest BinanceUserDataStream

  test "subscribe_message/0 returns the correct subscription message" do
    expected_message =
      Poison.encode!(%{method: "SUBSCRIBE", params: ["!userData"], id: "user_data_sub"})

    assert BinanceUserDataStream.subscribe_message() == expected_message
  end

  test "parse_message/1 returns :sub_ack for subscription acknowledgment" do
    msg = Poison.encode!(%{id: "user_data_sub", result: nil})
    assert BinanceUserDataStream.parse_message(msg) == {:sub_ack}
  end

  test "parse_message/1 returns :user_data_event for user data event" do
    msg = Poison.encode!(%{e: "event_type", some_key: "some_value"})

    assert BinanceUserDataStream.parse_message(msg) ==
             {:user_data_event, %{"e" => "event_type", "some_key" => "some_value"}}
  end

  test "parse_message/1 returns :unknown for unknown message" do
    msg = Poison.encode!(%{unknown_key: "unknown_value"})

    assert BinanceUserDataStream.parse_message(msg) ==
             {:unknown, %{"unknown_key" => "unknown_value"}}
  end

  test "parse_message/1 returns :error for invalid message" do
    msg = "invalid_message"
    assert match?({:error, _}, BinanceUserDataStream.parse_message(msg))
  end
end
