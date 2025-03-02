defmodule Trader.TradePlanner.ImplTest do
  @moduledoc "Tests for Impl"

  use ExUnit.Case
  use PropCheck

  alias Trader.TradePlanner.Impl
  alias Types.Opportunity
  alias Types.PlannedTrade
  alias Types.TradingSymbol

  property "plans trades with high enough notional value" do
    forall opportunity <- opportunity() do
      budget = Decimal.new(100)

      case Impl.plan_execution(opportunity, budget) do
        {:ok, plan} ->
          assert Enum.all?(plan, fn pt ->
                   notional = Decimal.mult(pt.order_qty, pt.order_price)
                   Decimal.gte?(notional, pt.trading_symbol.min_notional)
                 end)

        {:insufficient_balance, _} ->
          assert true
      end
    end
  end

  property "planned trades require budget or less of starting asset" do
    forall opportunity <- opportunity() do
      budget = Decimal.new(100)

      case Impl.plan_execution(opportunity, budget) do
        {:ok, plan} ->
          first_trade = hd(plan)

          starting_qty =
            case first_trade.trading_symbol.position do
              :long -> Decimal.mult(first_trade.order_qty, first_trade.order_price)
              :short -> first_trade.order_qty
            end

          assert Decimal.lte?(starting_qty, budget)

        {:insufficient_balance, _} ->
          assert true
      end
    end
  end

  property "asset from previous trade sufficient for the next one" do
    forall opportunity <- opportunity() do
      budget = Decimal.new(100)

      case Impl.plan_execution(opportunity, budget) do
        {:ok, plan} ->
          list_of_booleans =
            plan
            |> Enum.map_reduce(budget, fn pt, received_qty ->
              required_qty =
                case pt.trading_symbol.position do
                  :long -> Decimal.mult(pt.order_qty, pt.order_price)
                  :short -> pt.order_qty
                end

              newly_received_qty =
                case pt.trading_symbol.position do
                  :long -> pt.order_qty
                  :short -> Decimal.mult(pt.order_qty, pt.order_price)
                end

              {Decimal.gte?(received_qty, required_qty), newly_received_qty}
            end)
            |> elem(0)

          assert Enum.all?(list_of_booleans, fn b -> b end)

        {:insufficient_balance, _} ->
          assert true
      end
    end
  end

  ### generators

  defp opportunity do
    let [path <- non_empty(list(planned_trade())), profit <- profit(), capacity <- capacity()] do
      %Opportunity{
        path: path,
        profit: profit,
        capacity: capacity
      }
    end
  end

  defp planned_trade do
    let [
      order_qty <- order_qty(),
      order_price <- order_price(),
      trading_symbol <- trading_symbol()
    ] do
      %PlannedTrade{
        order_qty: order_qty,
        order_price: order_price,
        trading_symbol: trading_symbol
      }
    end
  end

  defp order_qty do
    pos_decimal()
  end

  defp order_price do
    pos_decimal()
  end

  defp profit do
    pos_decimal()
  end

  defp capacity do
    pos_decimal()
  end

  defp trading_symbol do
    let [
      symbol <- non_empty_string(),
      base_asset <- non_empty_string(),
      quote_asset <- non_empty_string(),
      base_asset_precision <- pos_integer(),
      quote_asset_precision <- pos_integer(),
      base_asset_increment <- pos_decimal(),
      quote_asset_increment <- pos_decimal(),
      position <- position()
    ] do
      %TradingSymbol{
        symbol: symbol,
        base_asset: base_asset,
        quote_asset: quote_asset,
        base_asset_precision: base_asset_precision,
        quote_asset_precision: quote_asset_precision,
        base_asset_increment: base_asset_increment,
        quote_asset_increment: quote_asset_increment,
        min_notional: Decimal.new(0),
        position: position
      }
    end
  end

  defp position do
    let pos <- union([:long, :short]) do
      pos
    end
  end

  defp pos_decimal do
    let float <- float(0.000001, :inf) do
      Decimal.from_float(float)
    end
  end

  defp non_empty_string do
    let charlist <- non_empty(elements(textdata())) do
      to_string(charlist)
    end
  end

  defp textdata do
    ~c"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789" ++
      ~c":;<=>?@ !#$%&'()*+-./[\\]^_`{|}~"
  end

  ## unit tests

  test "asset from previous trade sufficient for the next one" do
    opportunity = %Opportunity{
      profit: Decimal.new("0.000001"),
      capacity: Decimal.new("0.000001"),
      path: [
        %Types.PlannedTrade{
          trading_symbol: %Types.TradingSymbol{
            symbol: "65",
            position: :long,
            base_asset: "65",
            quote_asset: "65",
            base_asset_increment: Decimal.new("0.000001"),
            base_asset_precision: 1,
            quote_asset_increment: Decimal.new("0.000001"),
            quote_asset_precision: 1,
            min_notional: Decimal.new("0")
          },
          order_qty: Decimal.new("0.000001"),
          order_price: Decimal.new("0.000001")
        },
        %Types.PlannedTrade{
          trading_symbol: %Types.TradingSymbol{
            symbol: "65",
            position: :short,
            base_asset: "65",
            quote_asset: "65",
            base_asset_increment: Decimal.new("0.000001"),
            base_asset_precision: 1,
            quote_asset_increment: Decimal.new("0.000001"),
            quote_asset_precision: 1,
            min_notional: Decimal.new("0")
          },
          order_qty: Decimal.new("0.000001"),
          order_price: Decimal.new("0.000001")
        }
      ]
    }

    budget = Decimal.new(100)

    {:ok, plan} = Impl.plan_execution(opportunity, budget)

    list_of_booleans =
      plan
      |> Enum.map_reduce(budget, fn pt, received_qty ->
        required_qty =
          case pt.trading_symbol.position do
            :long -> Decimal.mult(pt.order_qty, pt.order_price)
            :short -> pt.order_qty
          end

        newly_received_qty =
          case pt.trading_symbol.position do
            :long -> pt.order_qty
            :short -> Decimal.mult(pt.order_qty, pt.order_price)
          end

        {Decimal.gte?(received_qty, required_qty), newly_received_qty}
      end)
      |> elem(0)

    assert Enum.all?(list_of_booleans, fn b -> b end)
  end
end
