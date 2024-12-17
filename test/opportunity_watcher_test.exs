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

    # profitable opportunity - buy 1 BTC with 1 USDT, sell for 2 USDT = 100% profit
    # capacity: 1.0 USDT (someone willing to buy 1 BTC for 2 USDT)
    OpportunityWatcher.update_symbol(pid, {"BTCUSDT", 1.0, 1.0, 2.0, 1.0})

    assert_receive {:"$gen_cast",
                    {:update_opportunities,
                     [
                       %{
                         path: [{"BTCUSDT", :long}, {"BTCUSDT", :short}],
                         profit: 1.0,
                         capacity: 1.0
                       }
                     ]}}
  end
end
