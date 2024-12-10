defmodule Kirnu do
  @moduledoc """
  Documentation for `Kirnu`.
  """

  def start do
    # discover trading paths
    symbols = Binance.get_symbols()
    trading_paths = Arbmapper.generate_trading_paths(symbols)
    symbol_list = Enum.map(symbols, & &1[:symbol])

    # create portfolio manager
    {:ok, pm_pid} = PortfolioManager.start_link(self())
    Process.register(pm_pid, :portfolio_manager)

    # create opportunity watcher
    {:ok, ow_pid} = OpportunityWatcher.start_link(pm_pid, trading_paths)
    Process.register(ow_pid, :opportunity_watcher)

    # create book streamer
    # TODO: create multiple streamers with max 1024 symbols each
    {:ok, bs_pid} = BookStreamer.start_link(ow_pid, symbol_list)
    Process.register(bs_pid, :book_streamer)

    %{portfolio_manager: pm_pid, opportunity_watcher: ow_pid, book_streamer: bs_pid}
  end
end
