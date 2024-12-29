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

  test "profitable opportunities passed to executor", %{pid: pid} do
    # empty opportunities
    PortfolioManager.send_opportunities(pid, [])
    refute_receive _

    # zero capacity
    PortfolioManager.send_opportunities(pid, [{[{"BTCUSDT", :long}, {"BTCUSDT", :short}], 1, 0}])
    refute_receive _

    # zero profitability
    PortfolioManager.send_opportunities(pid, [{[{"BTCUSDT", :long}, {"BTCUSDT", :short}], 0, 1}])
    refute_receive _

    # 2 profitable opportunities, in wrong order
    PortfolioManager.send_opportunities(pid, [
      {[{"DOGEBTC", :long}, {"BTCDOGE", :short}], 0.0, 0.0},
      {[{"ETHUSD", :long}, {"USDETH", :short}], 0.5, 0.5},
      {[{"BTCUSDT", :long}, {"BTCUSDT", :short}], 1.0, 1.0}
    ])

    assert_receive {:"$gen_cast",
     {:update_opportunities,
      [
        {
          # path
          [{"BTCUSDT", :long}, {"BTCUSDT", :short}],
          # profit
          1.0,
          # capacity
          1.0
        },
        {
          # path
          [{"ETHUSD", :long}, {"USDETH", :short}],
          # profit
          0.5,
          # capacity
          0.5
        }
      ]}}
  end
end
