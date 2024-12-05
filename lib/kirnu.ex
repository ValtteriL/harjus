defmodule Kirnu do
  @moduledoc """
  Documentation for `Kirnu`.
  """

  def start do

    # discover trading paths
    symbols = Binance.get_symbols()
    trading_paths = Arbmapper.generate_trading_paths(symbols)

    # create opportunity watcher for each trading path
    trading_paths |> Enum.each(fn path ->
      OpportunityWatcher.start_link(path)
    end)


    #Websocket.start_link("wss://stream.binance.com:9443/ws/BTCUSD@bookTicker", %{})
  end
end
