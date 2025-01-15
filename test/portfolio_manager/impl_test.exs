defmodule PortfolioManager.ImplTest do
  @moduledoc "Tests for Impl"

  alias PortfolioManager.Args
  alias PortfolioManager.Impl
  alias Types.Opportunity
  alias Types.TradingSymbol

  use ExUnit.Case, async: true

  test "filters out unprofitable opportunities" do
    state =
      Impl.new(%Args{
        min_profit_percentage: 0.1,
        min_capacity: 0.1,
        commission: 0.01,
        relative_asset_values: %{"BTC" => 1.0, "USDT" => 1.0}
      })

    opportunities = [opportunity("USDT", "BTC", 0.1, 0.1)]

    assert Impl.filter_opportunities(state, opportunities) == []
  end

  test "prioritizes by relative asset value" do
    state =
      Impl.new(%Args{
        min_profit_percentage: 0.1,
        min_capacity: 0.1,
        commission: 0.01,
        relative_asset_values: %{"BTC" => 1.0, "ETH" => 0.1, "USDT" => 0.01}
      })

    opportunities = [
      usdbtc = opportunity("USDT", "BTC", 1.0, 1.0),
      btceth = opportunity("BTC", "ETH", 1.0, 1.0)
    ]

    assert Impl.filter_opportunities(state, opportunities) == [
             usdbtc,
             btceth
           ]
  end

  test "prioritizes by capacity" do
    state =
      Impl.new(%Args{
        min_profit_percentage: 0.1,
        min_capacity: 0.1,
        commission: 0.01,
        relative_asset_values: %{"BTC" => 1.0, "ETH" => 0.1, "USDT" => 0.01}
      })

    opportunities = [
      smallercap = opportunity("USDT", "BTC", 1.0, 1.0),
      biggercap = opportunity("USDT", "BTC", 1.0, 2.0)
    ]

    assert Impl.filter_opportunities(state, opportunities) == [
             biggercap,
             smallercap
           ]
  end

  test "prioritizes by profit" do
    state =
      Impl.new(%Args{
        min_profit_percentage: 0.1,
        min_capacity: 0.1,
        commission: 0.01,
        relative_asset_values: %{"BTC" => 1.0, "ETH" => 0.1, "USDT" => 0.01}
      })

    opportunities = [
      smallerprofit = opportunity("USDT", "BTC", 1.0, 1.0),
      biggerprofit = opportunity("USDT", "BTC", 2.0, 1.0)
    ]

    assert Impl.filter_opportunities(state, opportunities) == [
             biggerprofit,
             smallerprofit
           ]
  end

  test "prioritizes by profit * capacity" do
    state =
      Impl.new(%Args{
        min_profit_percentage: 0.1,
        min_capacity: 0.1,
        commission: 0.01,
        relative_asset_values: %{"BTC" => 1.0, "ETH" => 0.1, "USDT" => 0.01}
      })

    opportunities = [
      bigger = opportunity("USDT", "BTC", 1.0, 5.0),
      smaller = opportunity("USDT", "BTC", 2.0, 2.0)
    ]

    assert Impl.filter_opportunities(state, opportunities) == [
             bigger,
             smaller
           ]
  end

  defp opportunity(base_asset, quote_asset, profit, capacity) do
    %Opportunity{
      path: [
        %TradingSymbol{
          symbol: "#{base_asset}#{quote_asset}",
          position: :long,
          base_asset: base_asset,
          quote_asset: quote_asset
        }
      ],
      profit: profit,
      capacity: capacity
    }
  end
end
