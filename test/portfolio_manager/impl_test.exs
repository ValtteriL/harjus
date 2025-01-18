defmodule PortfolioManager.ImplTest do
  @moduledoc "Tests for Impl"

  alias PortfolioManager.Args
  alias PortfolioManager.Impl
  alias Types.Opportunity
  alias Types.TradingSymbol

  use ExUnit.Case, async: true

  setup do
    # ReservedSymbols used by PortfolioManager
    {:ok, _pid} = Mutex.start_link(name: ReservedSymbols)
    :ok
  end

  test "prioritizes by relative asset value" do
    state =
      Impl.new(%Args{
        relative_asset_values: %{"BTC" => 1.0, "ETH" => 0.1, "USDT" => 0.01}
      })

    opportunities = [
      usdbtc = opportunity("USDT", "BTC", 1.0, 1.0),
      _btceth = opportunity("BTC", "ETH", 1.0, 1.0)
    ]

    assert Impl.filter_opportunities(state, opportunities) == [usdbtc]
  end

  test "prioritizes by capacity" do
    state =
      Impl.new(%Args{
        relative_asset_values: %{"BTC" => 1.0, "ETH" => 0.1, "USDT" => 0.01}
      })

    opportunities = [
      _smallercap = opportunity("USDT", "BTC", 1.0, 1.0),
      biggercap = opportunity("USDT", "BTC", 1.0, 2.0)
    ]

    assert Impl.filter_opportunities(state, opportunities) == [biggercap]
  end

  test "prioritizes by profit" do
    state =
      Impl.new(%Args{
        relative_asset_values: %{"BTC" => 1.0, "ETH" => 0.1, "USDT" => 0.01}
      })

    opportunities = [
      _smallerprofit = opportunity("USDT", "BTC", 1.0, 1.0),
      biggerprofit = opportunity("USDT", "BTC", 2.0, 1.0)
    ]

    assert Impl.filter_opportunities(state, opportunities) == [biggerprofit]
  end

  test "prioritizes by profit * capacity" do
    state =
      Impl.new(%Args{
        relative_asset_values: %{"BTC" => 1.0, "ETH" => 0.1, "USDT" => 0.01}
      })

    opportunities = [
      bigger = opportunity("USDT", "BTC", 1.0, 5.0),
      _smaller = opportunity("USDT", "BTC", 2.0, 2.0)
    ]

    assert Impl.filter_opportunities(state, opportunities) == [bigger]
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
