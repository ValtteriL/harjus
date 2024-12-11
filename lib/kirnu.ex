defmodule Kirnu do
  @moduledoc """
  Documentation for `Kirnu`.
  """

  def start do
    # discover trading paths
    symbols = Binance.get_symbols()
    {trading_paths, symbol_list} = Arbmapper.generate_trading_paths(symbols, ["BNB"])

    # create portfolio manager
    {:ok, pm_pid} = PortfolioManager.start_link(self())

    # create opportunity watcher
    {:ok, ow_pid} = OpportunityWatcher.start_link(pm_pid, trading_paths)

    # create multiple book streamers with max 1024 symbols each
    bs_pids =
      symbol_list
      |> Enum.chunk_every(1024)
      |> Enum.map(fn partial_list ->
        {:ok, bs_pid} = BookStreamer.start_link(ow_pid, partial_list)
        bs_pid
      end)

    %{portfolio_manager: pm_pid, opportunity_watcher: ow_pid, book_streamers: bs_pids}
  end
end
