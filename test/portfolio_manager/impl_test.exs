defmodule PortfolioManager.ImplTest do
  @moduledoc "Tests for Impl"

  alias PortfolioManager.Args
  alias PortfolioManager.Impl
  alias Types.Opportunity
  alias Types.TradingSymbol

  use ExUnit.Case, async: true

  setup do
    :ok
  end

  test "prioritizes by relative asset value" do
    state =
      Impl.new(%Args{
        relative_asset_values: %{
          "BTC" => Decimal.new(1),
          "ETH" => Decimal.from_float(0.1),
          "USDT" => Decimal.from_float(0.01)
        }
      })

    opportunities = [
      usdbtc = opportunity("USDT", "BTC", Decimal.new(1), Decimal.new(1)),
      _btceth = opportunity("BTC", "ETH", Decimal.new(1), Decimal.new(1))
    ]

    assert Impl.filter_opportunities(state, opportunities) == [usdbtc]
  end

  test "prioritizes by capacity" do
    state =
      Impl.new(%Args{
        relative_asset_values: %{
          "BTC" => Decimal.new(1),
          "ETH" => Decimal.from_float(0.1),
          "USDT" => Decimal.from_float(0.01)
        }
      })

    opportunities = [
      _smallercap = opportunity("USDT", "BTC", Decimal.new(1), Decimal.new(1)),
      biggercap = opportunity("USDT", "BTC", Decimal.new(1), Decimal.new(2))
    ]

    assert Impl.filter_opportunities(state, opportunities) == [biggercap]
  end

  test "prioritizes by profit" do
    state =
      Impl.new(%Args{
        relative_asset_values: %{
          "BTC" => Decimal.new(1),
          "ETH" => Decimal.from_float(0.1),
          "USDT" => Decimal.from_float(0.01)
        }
      })

    opportunities = [
      _smallerprofit = opportunity("USDT", "BTC", Decimal.new(1), Decimal.new(1)),
      biggerprofit = opportunity("USDT", "BTC", Decimal.new(2), Decimal.new(1))
    ]

    assert Impl.filter_opportunities(state, opportunities) == [biggerprofit]
  end

  test "prioritizes by profit * capacity" do
    state =
      Impl.new(%Args{
        relative_asset_values: %{
          "BTC" => Decimal.new(1),
          "ETH" => Decimal.from_float(0.1),
          "USDT" => Decimal.from_float(0.01)
        }
      })

    opportunities = [
      bigger = opportunity("USDT", "BTC", Decimal.new(1), Decimal.new(5)),
      _smaller = opportunity("USDT", "BTC", Decimal.new(2), Decimal.new(2))
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
