defmodule BinanceSpotStreamsTest do
  use ExUnit.Case
  doctest BinanceSpotStreams

  test "generates correct subscription message" do
    symbols = [
      "BTCETH",
      "ETHLTC",
      "LTCBTC"
    ]

    subscription_msg = BinanceSpotStreams.subscribe_message(symbols)

    assert subscription_msg ==
             "{\"params\":[\"btceth@bookTicker\",\"ethltc@bookTicker\",\"ltcbtc@bookTicker\"],\"method\":\"SUBSCRIBE\",\"id\":\"sub_id\"}"
  end

  test "parses subscription ack" do
    subscription_ack = Poison.encode!(%{id: "sub_id", result: nil})

    assert BinanceSpotStreams.parse_message(subscription_ack) == {:sub_ack}
  end

  test "parses bookticker update" do
    bookticker_update =
      Poison.encode!(%{
        s: "BTCETH",
        a: "0.1",
        A: "1.0",
        b: "0.2",
        B: "3.0",
        u: 123_456
      })

    assert BinanceSpotStreams.parse_message(bookticker_update) ==
             {:book_ticker_update, {"BTCETH", 0.1, 1.0, 0.2, 3.0}}
  end

  test "unknown message results in unknown" do
    unknown_message = Poison.encode!(%{hello: "world"})

    assert BinanceSpotStreams.parse_message(unknown_message) ==
             {:unknown, Poison.decode!(unknown_message)}
  end

  test "invalid json results in error" do
    invalid_message = "invalid message"

    assert {:error, _} = BinanceSpotStreams.parse_message(invalid_message)
  end
end
