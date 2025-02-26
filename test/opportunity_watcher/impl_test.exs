defmodule OpportunityWatcher.ImplTest do
  @moduledoc "Tests for Impl"

  alias OpportunityWatcher.Args
  alias OpportunityWatcher.Impl
  alias OpportunityWatcher.State
  alias Types.Opportunity
  alias Types.PlannedTrade
  alias Types.PriceUpdate
  alias Types.TradingSymbol

  use ExUnit.Case, async: true
  use PropCheck

  # turn off logging
  @moduletag :capture_log

  property "opportunity has a profit greater than or equal to min_profit_percentage" do
    forall {args, price_update} <- args_price_update() do
      state = %State{} = Impl.new(args)

      # collect opportunities from all price updates
      {_, opportunities} = Impl.price_update(state, price_update)

      assert Enum.all?(opportunities, fn x ->
               Decimal.gte?(x.profit, args.min_profit_percentage)
             end)
    end
  end

  property "opportunity has capacity greater than or equal to min_capacity" do
    forall {args, price_update} <- args_price_update() do
      state = %State{} = Impl.new(args)

      # collect opportunities from all price updates
      {_, opportunities} = Impl.price_update(state, price_update)

      assert Enum.all?(opportunities, fn x ->
               Decimal.gte?(x.capacity, args.min_capacity)
             end)
    end
  end

  property "opportunity must include symbol that was updated" do
    forall {args, price_update} <- args_price_update() do
      state = %State{} = Impl.new(args)

      # collect opportunities from all price updates
      {_, opportunities} = Impl.price_update(state, price_update)

      assert Enum.all?(opportunities, fn x ->
               Enum.any?(x.path, fn x -> x.trading_symbol.symbol == price_update.symbol end)
             end)
    end
  end

  ## Generators ##

  defp args_price_update do
    let args <- args() do
      let price_update <- price_update() do
        # price update must have symbols from trading paths
        symbols =
          args.trading_paths |> List.flatten() |> Enum.map(fn x -> x.symbol end) |> Enum.uniq()

        fixed_update = Map.replace!(price_update, :symbol, Enum.random(symbols))

        {args, fixed_update}
      end
    end
  end

  defp price_update do
    let [
      symbol <- non_empty_string(),
      ask_price <- non_neg_float(),
      ask_qty <- non_neg_float(),
      bid_price <- non_neg_float(),
      bid_qty <- non_neg_float()
    ] do
      %PriceUpdate{
        symbol: symbol,
        ask_price: Decimal.from_float(ask_price),
        ask_qty: Decimal.from_float(ask_qty),
        bid_price: Decimal.from_float(bid_price),
        bid_qty: Decimal.from_float(bid_qty)
      }
    end
  end

  defp args do
    let [
      min_profit_percentage <- non_neg_float(),
      min_capacity <- non_neg_float(),
      commission <- non_neg_float(),
      trading_paths <- non_empty(list(non_empty(list(trading_symbol()))))
    ] do
      %Args{
        min_profit_percentage: Decimal.from_float(min_profit_percentage),
        min_capacity: Decimal.from_float(min_capacity),
        commission: Decimal.from_float(commission),
        trading_paths: trading_paths
      }
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

  ## Unit tests ##

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
            quote_asset: "USDT",
            base_asset_increment: Decimal.new("0.01"),
            base_asset_precision: 8,
            min_notional: Decimal.from_float(0.0001)
          },
          %TradingSymbol{
            symbol: "BTCUSDT",
            position: :short,
            base_asset: "USDT",
            quote_asset: "BTC",
            base_asset_increment: Decimal.new("0.01"),
            base_asset_precision: 8,
            min_notional: Decimal.from_float(0.0001)
          }
        ]
      ]
    }

    state = Impl.new(args)

    {state, opportunities} =
      Impl.price_update(
        state,
        %PriceUpdate{
          symbol: "BTCUSDT",
          ask_price: Decimal.new("10000.0"),
          ask_qty: Decimal.new("1.0"),
          bid_price: Decimal.new("10000.0"),
          bid_qty: Decimal.new("1.0")
        }
      )

    assert opportunities == []

    {_state, opportunities} =
      Impl.price_update(
        state,
        %PriceUpdate{
          symbol: "BTCUSDT",
          ask_price: Decimal.new("1.0"),
          ask_qty: Decimal.new("1.0"),
          bid_price: Decimal.new("2.0"),
          bid_qty: Decimal.new("1.0")
        }
      )

    assert opportunities == [
             %Opportunity{
               path: [
                 %PlannedTrade{
                   trading_symbol: %TradingSymbol{
                     symbol: "BTCUSDT",
                     position: :long,
                     base_asset: "BTC",
                     quote_asset: "USDT",
                     base_asset_increment: Decimal.new("0.01"),
                     base_asset_precision: 8,
                     min_notional: Decimal.from_float(0.0001)
                   },
                   order_price: Decimal.new("1.0"),
                   order_qty: Decimal.new("1.00")
                 },
                 %PlannedTrade{
                   trading_symbol: %TradingSymbol{
                     symbol: "BTCUSDT",
                     position: :short,
                     base_asset: "USDT",
                     quote_asset: "BTC",
                     base_asset_increment: Decimal.new("0.01"),
                     base_asset_precision: 8,
                     min_notional: Decimal.from_float(0.0001)
                   },
                   order_price: Decimal.new("0.5"),
                   order_qty: Decimal.new("2.00")
                 }
               ],
               profit: Decimal.new("1"),
               capacity: Decimal.new("1.00")
             }
           ]
  end
end
