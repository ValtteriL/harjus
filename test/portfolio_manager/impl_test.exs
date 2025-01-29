defmodule PortfolioManager.ImplTest do
  @moduledoc "Tests for Impl"

  alias PortfolioManager.Args
  alias PortfolioManager.Impl
  alias Types.Opportunity
  alias Types.TradingSymbol

  use ExUnit.Case, async: true
  use PropCheck

  # turn off logging
  @moduletag :capture_log

  property "emits list of single opportunity" do
    forall [args, opportunities] <- [args(), opportunities()] do
      state = %Args{} = Impl.new(args)
      assert Enum.count(Impl.filter_opportunities(state, opportunities)) == 1
    end
  end

  property "emitted opportunity is one of input opportunities" do
    forall [args, opportunities] <- [args(), opportunities()] do
      state = %Args{} = Impl.new(args)

      assert Enum.member?(
               opportunities,
               Enum.at(Impl.filter_opportunities(state, opportunities), 0)
             )
    end
  end

  property "emitted element has highest value" do
    forall [args, opportunities] <- [args(), opportunities()] do
      state = %Args{} = Impl.new(args)

      best_opportunity = Enum.at(Impl.filter_opportunities(state, opportunities), 0)

      %{path: [firstsymbol | _], profit: profit, capacity: cap} = best_opportunity

      best_opportunity_asset_value =
        Map.get(args.relative_asset_values, firstsymbol.quote_asset, Decimal.new(0))

      best_opportunity_value =
        Decimal.mult(
          Decimal.mult(best_opportunity.profit, best_opportunity.capacity),
          best_opportunity_asset_value
        )

      assert Enum.all?(opportunities, fn opportunity ->
               %{path: [firstsymbol1 | _], profit: profit1, capacity: cap1} = opportunity

               value =
                 Map.get(args.relative_asset_values, firstsymbol1.quote_asset, Decimal.new(0))

               opportunity_value = Decimal.mult(Decimal.mult(profit1, cap1), value)

               Decimal.lte?(opportunity_value, best_opportunity_value)
             end)
    end
  end

  ## Generators ##

  defp opportunities do
    let opps <- non_empty(list(opportunity())) do
      opps
    end
  end

  defp opportunity do
    let profit <- decimal() do
      let capacity <- decimal() do
        let path <- path() do
          %Opportunity{
            path: path,
            profit: profit,
            capacity: capacity
          }
        end
      end
    end
  end

  defp path do
    let p <- non_empty(list(trading_symbol())) do
      p
    end
  end

  defp args do
    let relative_asset_values <- map(non_empty_string(), decimal()) do
      %Args{relative_asset_values: relative_asset_values}
    end
  end

  defp decimal do
    let float <- float() do
      Decimal.from_float(float)
    end
  end

  def trading_symbol do
    let symbol <- non_empty_string() do
      let position <- union([:long, :short]) do
        let base_asset <- non_empty_string() do
          let quote_asset <- non_empty_string() do
            %TradingSymbol{
              symbol: symbol,
              position: position,
              base_asset: base_asset,
              quote_asset: quote_asset
            }
          end
        end
      end
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
