defmodule PortfolioManagerTest do
  @moduledoc "Tests for PortfolioManager"
  use ExUnit.Case, async: false
  doctest PortfolioManager

  setup do
    pm_args = %{
      min_profit_percentage: 0.01,
      min_capacity: 0.01,
      commission: 0.01
    }

    # pass self -> receive msgs meant for portfolio manager
    Process.register(self(), Executor)
    {:ok, pid} = PortfolioManager.start_link(pm_args)
    %{pid: pid}
  end

  test "profitable opportunities passed to executor", %{pid: _pid} do
    # empty opportunities
    PortfolioManager.send_opportunities([])
    refute_receive _

    # zero capacity
    PortfolioManager.send_opportunities([
      {[
         %TradingSymbol{symbol: "BTCUSDT", position: :long},
         %TradingSymbol{symbol: "BTCUSDT", position: :short}
       ], 1, 0}
    ])

    refute_receive _

    # zero profitability
    PortfolioManager.send_opportunities([
      {[
         %TradingSymbol{symbol: "BTCUSDT", position: :long},
         %TradingSymbol{symbol: "BTCUSDT", position: :short}
       ], 0, 1}
    ])

    refute_receive _

    # 2 profitable opportunities, in wrong order
    PortfolioManager.send_opportunities([
      {[
         %TradingSymbol{symbol: "DOGEBTC", position: :long},
         %TradingSymbol{symbol: "BTCDOGE", position: :short}
       ], 0.0, 0.0},
      {[
         %TradingSymbol{symbol: "ETHUSD", position: :long},
         %TradingSymbol{symbol: "USDETH", position: :short}
       ], 0.5, 0.5},
      {[
         %TradingSymbol{symbol: "BTCUSDT", position: :long},
         %TradingSymbol{symbol: "BTCUSDT", position: :short}
       ], 1.0, 1.0}
    ])

    assert_receive {:"$gen_cast",
     {:update_opportunities,
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
        },
        {
          # path
          [
            %TradingSymbol{symbol: "ETHUSD", position: :long},
            %TradingSymbol{symbol: "USDETH", position: :short}
          ],
          # profit
          0.5,
          # capacity
          0.5
        }
      ]}}
  end
end
