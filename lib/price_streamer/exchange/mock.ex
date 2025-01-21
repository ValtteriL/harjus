defmodule PriceStreamer.Exchange.Mock do
  @moduledoc "Mock for receiving price updates from the exchange"

  alias Types.PriceUpdate

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

    PriceStreamer.price_update(%PriceUpdate{
      symbol: symbol,
      ask_price: Decimal.new(ask_price),
      ask_qty: Decimal.new(ask_qty),
      bid_price: Decimal.new(bid_price),
      bid_qty: Decimal.new(bid_qty)
    })

    :timer.sleep(1000)
    simulate_updates(symbols)
  end
end
