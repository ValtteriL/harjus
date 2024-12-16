defmodule OpportunityWatcherTest do
  use ExUnit.Case, async: true
  doctest OpportunityWatcher

  setup do
    trading_paths = [[{"BTCUSDT", :long}, {"BTCUSDT", :short}]]
    # pass self -> receive msgs meant for portfolio manager
    Process.register(self(), PortfolioManager)
    {:ok, pid} = OpportunityWatcher.start_link(trading_paths)
    %{pid: pid}
  end

  test "symbol update emits opportunities", %{pid: pid} do
    # 1:1 - no opportunity
    OpportunityWatcher.update_symbol(pid, {"BTCUSDT", 10000.0, 1.0, 10000.0, 1.0})

    # negative oppotunities should not be emitted
    refute_receive _

    # TODO: make sense of this
    # OpportunityWatcher.update_symbol(pid, {"BTCUSDT", 1.0, 100.0, 2.0, 100.0}) # WHY DOES NOT WORK??

    # MEANWHILE THESE BOTH WORK (only one should work)
    OpportunityWatcher.update_symbol(pid, {"BTCUSDT", 1.0, 1.0, 0.1, 100})
    OpportunityWatcher.update_symbol(pid, {"BTCUSDT", 0.1, 1.0, 1.0, 100})

    assert_receive {:"$gen_cast",
                    {:update_opportunities,
                     [%{path: [{"BTCUSDT", :long}, {"BTCUSDT", :short}], profit: _, capacity: _}]}}
  end
end
