defmodule Kirnu do
  @moduledoc """
  Documentation for `Kirnu`.
  """

  def start do
    symbols = Binance.get_symbols()
    _trading_paths = Arbmapper.generate_trading_paths(symbols)

    Websocket.start_link("wss://stream.binance.com:9443/ws/BTCUSD@bookTicker", %{})
  end
end
