defmodule PortfolioManager.ImplTest do
  @moduledoc "Tests for Impl"

  alias PortfolioManager.Args
  alias PortfolioManager.BalanceMock
  alias PortfolioManager.Impl
  alias Types.Opportunity
  alias Types.PlannedTrade
  alias Types.TradingSymbol

  use ExUnit.Case, async: true
  use PropCheck

  import Mox

  # turn off logging
  @moduletag :capture_log

  setup :verify_on_exit!

  property "emits list of single opportunity" do
    forall [args, opportunities] <- [args(), opportunities()] do
      BalanceMock
      |> stub(:get, fn _ -> Decimal.new(1) end)

      state = %Args{} = Impl.new(args)
      assert Enum.count(Impl.filter_opportunities(state, opportunities)) == 1
    end
  end

  property "emitted opportunity is one of input opportunities" do
    forall [args, opportunities] <- [args(), opportunities()] do
      BalanceMock
      |> stub(:get, fn _ -> Decimal.new(1) end)

      state = %Args{} = Impl.new(args)

      assert Enum.member?(
               opportunities,
               Enum.at(Impl.filter_opportunities(state, opportunities), 0)
             )
    end
  end

  property "emitted element has highest value" do
    forall [args, opportunities] <- [args(), opportunities()] do
      BalanceMock
      |> stub(:get, fn _ -> Decimal.new(1) end)

      state = %Args{} = Impl.new(args)

      best_opportunity = Enum.at(Impl.filter_opportunities(state, opportunities), 0)
      best_opportunity_value = get_opportunity_value(best_opportunity, args.relative_asset_values)

      assert Enum.all?(opportunities, fn opportunity ->
               value = get_opportunity_value(opportunity, args.relative_asset_values)
               Decimal.lte?(value, best_opportunity_value)
             end)
    end
  end

  property "prioritizes by balance when profits and capacities are equal" do
    forall [btc_price, eth_price] <- [pos_decimal(), pos_decimal()] do
      PortfolioManager.BalanceMock
      |> stub(:get, fn
        "BTC" -> btc_price
        "ETH" -> eth_price
        _ -> Decimal.new(0)
      end)

      state =
        Impl.new(%Args{
          relative_asset_values: %{
            "BTC" => Decimal.new(1),
            "ETH" => Decimal.new(1),
            "USDT" => Decimal.new(1)
          }
        })

      bigger_balance = Decimal.max(btc_price, eth_price)

      opportunities = [
        _btc = opportunity("USDT", "BTC", Decimal.new(1), bigger_balance),
        _eth = opportunity("USDT", "ETH", Decimal.new(1), bigger_balance)
      ]

      opportunity = Enum.at(Impl.filter_opportunities(state, opportunities), 0)

      %{path: [%{trading_symbol: %{quote_asset: q}} | _]} = opportunity

      ret =
        case(q) do
          "BTC" -> Decimal.gte?(btc_price, eth_price)
          "ETH" -> Decimal.gte?(eth_price, btc_price)
          _ -> false
        end

      assert ret
    end
  end

  ## Generators ##

  defp opportunities do
    let opps <- non_empty(list(opportunity())) do
      opps
    end
  end

  defp opportunity do
    let [
      profit <- decimal(),
      capacity <- pos_decimal(),
      path <- path()
    ] do
      %Opportunity{
        path: path,
        profit: profit,
        capacity: capacity
      }
    end
  end

  defp path do
    let p <- non_empty(list(planned_trade())) do
      p
    end
  end

  defp args do
    let relative_asset_values <- map(non_empty_string(), pos_decimal()) do
      %Args{relative_asset_values: relative_asset_values}
    end
  end

  defp pos_decimal do
    let float <- non_neg_float() do
      Decimal.from_float(float)
    end
  end

  defp decimal do
    let float <- float() do
      Decimal.from_float(float)
    end
  end

  defp trading_symbol do
    let [
      symbol <- non_empty_string(),
      position <- union([:long, :short]),
      base_asset <- non_empty_string(),
      quote_asset <- non_empty_string(),
      precision <- pos_integer(),
      increment <- pos_decimal(),
      min_notional <- pos_decimal()
    ] do
      %TradingSymbol{
        symbol: symbol,
        position: position,
        base_asset: base_asset,
        quote_asset: quote_asset,
        base_asset_increment: increment,
        base_asset_precision: precision,
        min_notional: min_notional
      }
    end
  end

  defp planned_trade do
    let [
      trading_symbol <- trading_symbol(),
      order_qty <- pos_decimal(),
      order_price <- pos_decimal()
    ] do
      %PlannedTrade{
        trading_symbol: trading_symbol,
        order_qty: order_qty,
        order_price: order_price
      }
    end
  end

  def non_empty_string do
    let charlist <- non_empty(elements(textdata())) do
      to_string(charlist)
    end
  end

  defp textdata do
    ~c"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789" ++
      ~c":;<=>?@ !#$%&'()*+-./[\\]^_`{|}~"
  end

  ## Unit tests ##

  test "prioritizes by relative asset value" do
    PortfolioManager.BalanceMock
    |> stub(:get, fn _ -> Decimal.new(1) end)

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
    PortfolioManager.BalanceMock
    |> stub(:get, fn _ -> Decimal.new(10) end)

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
    PortfolioManager.BalanceMock
    |> stub(:get, fn _ -> Decimal.new(1) end)

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
    PortfolioManager.BalanceMock
    |> stub(:get, fn _ -> Decimal.new(5) end)

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
        %PlannedTrade{
          trading_symbol: %TradingSymbol{
            symbol: "#{base_asset}#{quote_asset}",
            position: :long,
            base_asset: base_asset,
            quote_asset: quote_asset,
            base_asset_increment: Decimal.new("0.01"),
            base_asset_precision: 8,
            min_notional: Decimal.from_float(0.001)
          },
          order_price: Decimal.new(1),
          order_qty: Decimal.new(1)
        }
      ],
      profit: profit,
      capacity: capacity
    }
  end

  defp get_opportunity_value(opportunity, relative_asset_values) do
    %{path: [pt | _], profit: profit, capacity: cap} = opportunity

    asset_value =
      Map.get(relative_asset_values, pt.trading_symbol.quote_asset, Decimal.new(0))

    Decimal.mult(
      Decimal.mult(profit, Decimal.min(cap, BalanceMock.get(pt.trading_symbol.quote_asset))),
      asset_value
    )
  end
end
