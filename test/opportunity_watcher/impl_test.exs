defmodule OpportunityWatcher.ImplTest do
  @moduledoc "Tests for Impl"

  alias OpportunityWatcher.Args
  alias OpportunityWatcher.Impl
  alias Types.Opportunity
  alias Types.TradingSymbol

  use ExUnit.Case, async: true

  test "returns opportunities" do
    args = %Args{
      min_profit_percentage: 0.0,
      min_capacity: 0.0,
      commission: 0.0,
      trading_paths: [
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
    }

    state = Impl.new(args)

    {state, opportunities} = Impl.price_update(state, {"BTCUSDT", 10_000.0, 1.0, 10_000.0, 1.0})
    assert opportunities == []

    {_state, opportunities} = Impl.price_update(state, {"BTCUSDT", 1.0, 1.0, 2.0, 1.0})

    assert opportunities == [
             %Opportunity{
               path: [
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
               profit: 1.0,
               capacity: 1.0
             }
           ]
  end
end
