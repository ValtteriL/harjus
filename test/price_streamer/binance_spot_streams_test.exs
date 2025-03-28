defmodule PriceStreamer.Exchange.Binance.SpotStreamTest do
  @moduledoc "Tests for SpotStream"

  alias PriceStreamer.Exchange.Binance.SpotStream

  use ExUnit.Case
  doctest SpotStream

  test "generates correct subscription message" do
    symbols = [
      "BTCETH",
      "ETHLTC",
      "LTCBTC"
    ]

    subscription_msg = SpotStream.subscribe_message(symbols)

    assert subscription_msg ==
             "{\"params\":[\"btceth@bookTicker\",\"ethltc@bookTicker\",\"ltcbtc@bookTicker\"],\"method\":\"SUBSCRIBE\",\"id\":\"sub_id\"}"
  end

  test "parses subscription ack" do
    subscription_ack = Poison.encode!(%{id: "sub_id", result: nil})

    assert SpotStream.parse_message(subscription_ack) == {:sub_ack}
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

    assert SpotStream.parse_message(bookticker_update) ==
             {:book_ticker_update, bookticker_update}
  end

  test "unknown message results in unknown" do
    unknown_message = Poison.encode!(%{hello: "world"})

    assert SpotStream.parse_message(unknown_message) ==
             {:unknown, Poison.decode!(unknown_message)}
  end

  test "invalid json results in error" do
    invalid_message = "invalid message"

    assert {:error, _} = SpotStream.parse_message(invalid_message)
  end
end
