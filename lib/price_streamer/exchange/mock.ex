defmodule PriceStreamer.Exchange.Mock do
  @moduledoc "Mock for receiving price updates from the exchange"

  @spec new([String.t()]) :: :ok
  def new(symbols) do
    Task.start_link(fn ->
      simulate_updates(symbols)
    end)

    :ok
  end

  def simulate_updates(symbols) do
    # choose a random symbol every 1 second

    symbol = Enum.random(symbols)

    ask_price = Enum.random(2..100)
    ask_qty = Enum.random(1..100)
    bid_qty = Enum.random(1..100)

    bid_price = ask_price - 1

    Engine.price_update(
      Jason.encode!(%{
        u: 123_456_789,
        s: symbol,
        a: Decimal.new(ask_price),
        A: Decimal.new(ask_qty),
        b: Decimal.new(bid_price),
        B: Decimal.new(bid_qty)
      })
    )

    :timer.sleep(1000)
    simulate_updates(symbols)
  end
end
