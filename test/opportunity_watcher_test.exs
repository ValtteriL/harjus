defmodule OpportunityWatcherTest do
  @moduledoc "Tests for OpportunityWatcher"
  use ExUnit.Case, async: false
  doctest OpportunityWatcher

  setup do
    trading_paths = [
      [
        %TradingSymbol{
          symbol: "BTCUSDT",
          position: :long,
          base_asset: "BTC",
          quote_asset: "USDT"
        },
        %TradingSymbol{
          symbol: "BTCUSDT",
          position: :short,
          base_asset: "USDT",
          quote_asset: "BTC"
        }
      ]
    ]

    # pass self -> receive msgs meant for portfolio manager
    Process.register(self(), PortfolioManager)
    {:ok, pid} = OpportunityWatcher.start_link(trading_paths)
    %{pid: pid}
  end

  test "symbol update emits opportunities", %{pid: _pid} do
    # 1:1 - no opportunity
    OpportunityWatcher.price_update({"BTCUSDT", 10_000.0, 1.0, 10_000.0, 1.0})

    # negative oppotunities should not be emitted
    refute_receive _

    # profitable opportunity - buy 1 BTC with 1 USDT, sell for 2 USDT = 100% profit
    # capacity: 1.0 USDT (someone willing to buy 1 BTC for 2 USDT)
    OpportunityWatcher.price_update({"BTCUSDT", 1.0, 1.0, 2.0, 1.0})

    assert_receive {:"$gen_cast",
     {:opportunity_update,
      [
        {
          # path
          [
            %TradingSymbol{symbol: "BTCUSDT", position: :long},
            %TradingSymbol{symbol: "BTCUSDT", position: :short}
          ],
          # profit
          1.0,
          # capacity
          1.0
        }
      ]}}
  end
end
