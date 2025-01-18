defmodule OpportunityWatcher.ImplTest do
  @moduledoc "Tests for Impl"

  alias OpportunityWatcher.Args
  alias OpportunityWatcher.Impl
  alias Types.Opportunity
  alias Types.TradingSymbol

  use ExUnit.Case, async: true

  test "returns opportunities" do
    args = %Args{
      min_profit_percentage: Decimal.new(0),
      min_capacity: Decimal.new(0),
      commission: Decimal.new(0),
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

    {state, opportunities} =
      Impl.price_update(
        state,
        {"BTCUSDT", Decimal.new("10000.0"), Decimal.new("1.0"), Decimal.new("10000.0"),
         Decimal.new("1.0")}
      )

    assert opportunities == []

    {_state, opportunities} =
      Impl.price_update(
        state,
        {"BTCUSDT", Decimal.new("1.0"), Decimal.new("1.0"), Decimal.new("2.0"),
         Decimal.new("1.0")}
      )

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
               profit: Decimal.new("1"),
               capacity: Decimal.new("1.00")
             }
           ]
  end
end
