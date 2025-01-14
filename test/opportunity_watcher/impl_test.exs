defmodule OpportunityWatcher.ImplTest do
  @moduledoc "Tests for Impl"

  alias OpportunityWatcher.Impl
  alias Types.Opportunity
  alias Types.TradingSymbol

  use ExUnit.Case, async: true

  test "returns opportunities" do
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

    state = Impl.new(trading_paths)

    state = Impl.price_update(state, {"BTCUSDT", 10_000.0, 1.0, 10_000.0, 1.0})
    assert Impl.get_opportunities(state) == []

    state = Impl.price_update(state, {"BTCUSDT", 1.0, 1.0, 2.0, 1.0})

    assert Impl.get_opportunities(state) == [
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
