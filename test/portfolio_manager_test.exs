defmodule PortfolioManagerTest do
  @moduledoc "Tests for PortfolioManager"
  use ExUnit.Case, async: false
  doctest PortfolioManager

  alias Types.TradingSymbol

  setup do
    pm_args = %PortfolioManager.Args{
      min_profit_percentage: 0.01,
      min_capacity: 0.01,
      commission: 0.01,
      relative_asset_values: %{"BTC" => 1.0, "USDT" => 1.0, "ETH" => 1.0}
    }

    # pass self -> receive msgs meant for portfolio manager
    Process.register(self(), Executor)
    {:ok, pid} = PortfolioManager.start_link(pm_args)
    %{pid: pid}
  end

  test "profitable opportunities passed to executor", %{pid: _pid} do
    # empty opportunities
    PortfolioManager.opportunity_update([])
    refute_receive _

    # zero capacity
    PortfolioManager.opportunity_update([
      {[
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
       ], 1, 0}
    ])

    refute_receive _

    # zero profitability
    PortfolioManager.opportunity_update([
      {[
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
       ], 0, 1}
    ])

    refute_receive _

    # 2 profitable opportunities, in wrong order
    PortfolioManager.opportunity_update([
      {[
         %TradingSymbol{
           symbol: "DOGEBTC",
           position: :long,
           base_asset: "DOGE",
           quote_asset: "BTC"
         },
         %TradingSymbol{
           symbol: "BTCDOGE",
           position: :short,
           base_asset: "BTC",
           quote_asset: "DOGE"
         }
       ], 0.0, 0.0},
      {[
         %TradingSymbol{symbol: "ETHUSD", position: :long, base_asset: "ETH", quote_asset: "USD"},
         %TradingSymbol{symbol: "USDETH", position: :short, base_asset: "USD", quote_asset: "ETH"}
       ], 0.5, 0.5},
      {[
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
       ], 1.0, 1.0}
    ])

    assert_receive {:"$gen_cast",
     {:execute_opportunity,
      {
        # path
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
        ],
        # profit
        1.0,
        # capacity
        1.0
      }}}
  end
end
