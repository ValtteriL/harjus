defmodule Kirnu do
  @moduledoc """
  Documentation for `Kirnu`.
  """

  def start do
    # discover trading paths
    symbols = Binance.get_symbols()
    trading_paths = Arbmapper.generate_trading_paths(symbols)

    # create portfolio manager
    {:ok, pm_pid} = PortfolioManager.start_link(self())

    # create opportunity watcher
    OpportunityWatcher.start_link(pm_pid, trading_paths)

    # Websocket.start_link("wss://stream.binance.com:9443/ws/BTCUSD@bookTicker", %{})
  end
end
