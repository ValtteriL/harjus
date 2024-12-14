defmodule OpportunityWatcherTest do
  use ExUnit.Case, async: true
  doctest OpportunityWatcher

  setup do
    trading_paths = [["BTCUSDT", "USDTBTC"]]
    # pass self -> receive msgs meant for portfolio manager
    Process.register(self(), PortfolioManager)
    {:ok, pid} = OpportunityWatcher.start_link(trading_paths)
    %{pid: pid}
  end

  test "symbol update emits opportunities", %{pid: pid} do
    OpportunityWatcher.update_symbol(pid, {"BTCUSDT", 10000.0, 1.0})

    # negative oppotunities should not be emitted
    refute_receive _

    OpportunityWatcher.update_symbol(pid, {"USDTBTC", 0.00005, 1337.1337})

    assert_receive {:"$gen_cast",
                    {:update_opportunities,
                     [%{path: ["BTCUSDT", "USDTBTC"], profit: _, capacity: _}]}}
  end
end
