defmodule Trader.TradePlanner.ImplTest do
  @moduledoc "Tests for Impl"

  use ExUnit.Case
  use PropCheck

  alias Trader.TradePlanner.Impl
  alias Types.Opportunity
  alias Types.PlannedTrade
  alias Types.TradingSymbol

  # problem: generated opportunities may be negative
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

  ### generators

  defp opportunity do
    let [path <- non_empty(list(planned_trade())), profit <- profit(), capacity <- capacity()] do
      %Opportunity{
        path: path |> Enum.take(5),
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
    let float <- float(0.001, :inf) do
      Decimal.from_float(float)
    end
  end

  defp order_price do
    let float <- float(0.001, :inf) do
      Decimal.from_float(float)
    end
  end

  defp profit do
    let float <- float(0.001, :inf) do
      Decimal.from_float(float)
    end
  end

  defp capacity do
    let float <- float(0.1, :inf) do
      Decimal.from_float(float)
    end
  end

  defp trading_symbol do
    let [
      symbol <- non_empty_string(),
      base_asset <- non_empty_string(),
      quote_asset <- non_empty_string(),
      min_notional <- pos_decimal(),
      position <- position()
    ] do
      %TradingSymbol{
        symbol: symbol,
        base_asset: base_asset,
        quote_asset: quote_asset,
        base_asset_precision: 8,
        quote_asset_precision: 8,
        base_asset_increment: Decimal.from_float(0.000001),
        quote_asset_increment: Decimal.from_float(0.000001),
        min_notional: min_notional,
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
          order_qty: Decimal.new("0.001"),
          order_price: Decimal.new("0.001")
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
          order_qty: Decimal.new("0.001"),
          order_price: Decimal.new("0.001")
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

  test "asset from previous trade sufficient for the next one 2" do
    opportunity = %Opportunity{
      path: [
        %Types.PlannedTrade{
          trading_symbol: %Types.TradingSymbol{
            symbol: "ADAEUR",
            position: :short,
            base_asset: "ADA",
            quote_asset: "EUR",
            base_asset_increment: Decimal.new("0.10000000"),
            base_asset_precision: 8,
            quote_asset_increment: Decimal.new("0.00010000"),
            quote_asset_precision: 8,
            min_notional: Decimal.new("5.00000000")
          },
          order_qty: Decimal.new("8117.90000000"),
          order_price: Decimal.new("0.81700000")
        },
        %Types.PlannedTrade{
          trading_symbol: %Types.TradingSymbol{
            symbol: "EURUSDC",
            position: :short,
            base_asset: "EUR",
            quote_asset: "USDC",
            base_asset_increment: Decimal.new("0.10000000"),
            base_asset_precision: 8,
            quote_asset_increment: Decimal.new("0.00010000"),
            quote_asset_precision: 8,
            min_notional: Decimal.new("5.00000000")
          },
          order_qty: Decimal.new("7835.00000000"),
          order_price: Decimal.new("1.03610000")
        },
        %Types.PlannedTrade{
          trading_symbol: %Types.TradingSymbol{
            symbol: "ADAUSDC",
            position: :long,
            base_asset: "ADA",
            quote_asset: "USDC",
            base_asset_increment: Decimal.new("0.10000000"),
            base_asset_precision: 8,
            quote_asset_increment: Decimal.new("0.00010000"),
            quote_asset_precision: 8,
            min_notional: Decimal.new("5.00000000")
          },
          order_qty: Decimal.new("9432.90000000"),
          order_price: Decimal.new("0.83060000")
        }
      ],
      profit: Decimal.new("0.016080854243446063086925114"),
      capacity: Decimal.new("6632.355856086596999999999999")
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
