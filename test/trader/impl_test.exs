defmodule Trader.ImplTest do
  @moduledoc "Tests for Impl"

  use ExUnit.Case
  use PropCheck

  alias Trader.Error.InsufficientBalanceError
  alias Trader.Error.SymbolAlreadyReservedError
  alias Trader.Impl
  alias Types.Opportunity
  alias Types.PlannedTrade
  alias Types.TradeReport
  alias Types.TradingSymbol
  require Decimal

  import Mox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  # turn off logging
  @moduletag :capture_log

  property "fails if any symbol in path already reserved" do
    forall [opportunity] <-
             [
               opportunity_with_duplicate_symbols()
             ] do
      # setup mocks
      Trader.Balance.TestMock
      |> stub(:update, fn _asset, _amount -> :ok end)

      Trader.TradeClient.Exchange.TestMock
      |> expect(:new, fn -> :ok end)

      # init
      Impl.new()

      raises_correct_error =
        try do
          Impl.execute_opportunity(opportunity)
        rescue
          SymbolAlreadyReservedError -> true
        else
          _ -> false
        end

      assert raises_correct_error
    end
  end

  defp trade_report_for_symbol(%TradingSymbol{position: position, symbol: symbol}) do
    {:executed,
     %TradeReport{
       symbol: symbol,
       position: position,
       quantity_base: Decimal.new(1),
       quantity_quote: Decimal.new(1),
       fees: [
         %Types.TradeReport.Fee{
           fee_currency: "BNB",
           fee_amount: Decimal.from_float(0.1)
         }
       ]
     }}
  end

  ## Generators ##

  defp opportunity_with_duplicate_symbols do
    let opportunity <- opportunity() do
      # make symbols duplicate
      duplicate_path = opportunity.path ++ opportunity.path
      Map.replace(opportunity, :path, duplicate_path)
    end
  end

  defp opportunity do
    let [path <- path(), profit <- pos_decimal(), capacity <- pos_decimal()] do
      %Opportunity{
        path: path,
        profit: profit,
        capacity: capacity
      }
    end
  end

  defp pos_decimal do
    let float <- float(0.000001, :inf) do
      Decimal.from_float(float)
    end
  end

  defp path do
    let path <- non_empty(list(planned_trade())) do
      first_base_asset = Enum.at(path, 0).trading_symbol.base_asset

      path
      # make symbols in path unique
      |> Enum.uniq_by(fn p -> p.trading_symbol.symbol end)
      # make sure the next quote asset is the same as the previous base asset
      |> Enum.map_reduce(first_base_asset, fn ps, prev_base_asset ->
        ts = ps.trading_symbol
        new_ts = ts |> Map.put(:quote_asset, prev_base_asset)
        new_ps = ps |> Map.put(:trading_symbol, new_ts)
        {new_ps, ts.base_asset}
      end)
      |> elem(0)
    end
  end

  defp trading_symbol do
    let [
      symbol <- non_empty_string(),
      position <- union([:long, :short]),
      base_asset <- non_empty_string(),
      quote_asset <- non_empty_string(),
      min_notional <- pos_decimal()
    ] do
      %TradingSymbol{
        symbol: symbol,
        position: position,
        base_asset: base_asset,
        quote_asset: quote_asset,
        base_asset_increment: Decimal.from_float(0.01),
        base_asset_precision: 8,
        quote_asset_increment: Decimal.from_float(0.01),
        quote_asset_precision: 8,
        min_notional: min_notional
      }
    end
  end

  defp planned_trade do
    let [
      trading_symbol <- trading_symbol(),
      order_price <- pos_decimal(),
      order_qty <- pos_decimal()
    ] do
      %PlannedTrade{
        trading_symbol: trading_symbol,
        order_price: order_price,
        order_qty: order_qty
      }
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

  # unit tests

  test "succeeds when balace and free symbols" do
    opportunity = %Opportunity{
      path: [
        %PlannedTrade{
          trading_symbol: %TradingSymbol{
            symbol: "BTCUSDT",
            position: :long,
            base_asset: "BTC",
            quote_asset: "USDT",
            base_asset_increment: Decimal.from_float(0.01),
            base_asset_precision: 8,
            quote_asset_increment: Decimal.from_float(0.01),
            quote_asset_precision: 8,
            min_notional: Decimal.from_float(10.0)
          },
          order_price: Decimal.from_float(100.0),
          order_qty: Decimal.from_float(0.1)
        },
        %PlannedTrade{
          trading_symbol: %TradingSymbol{
            symbol: "ETHBTC",
            position: :short,
            base_asset: "ETH",
            quote_asset: "BTC",
            base_asset_increment: Decimal.from_float(0.01),
            base_asset_precision: 8,
            quote_asset_increment: Decimal.from_float(0.01),
            quote_asset_precision: 8,
            min_notional: Decimal.from_float(0.001)
          },
          order_price: Decimal.from_float(0.1),
          order_qty: Decimal.from_float(0.1)
        }
      ],
      profit: Decimal.from_float(0.01),
      capacity: Decimal.from_float(0.1)
    }

    # setup mocks
    Trader.Balance.TestMock
    |> stub(:update, fn _asset, _amount -> :ok end)
    |> expect(:reserve_upto, fn _asset, _amount, _increment, _precision ->
      opportunity.capacity
    end)

    Trader.TradeClient.Exchange.TestMock
    |> expect(:new, fn -> :ok end)
    |> expect(:limit_order, Enum.count(opportunity.path), fn trading_symbol, _quantity, _price ->
      trade_report_for_symbol(trading_symbol)
    end)

    # init
    Impl.new()

    assert :ok == Impl.execute_opportunity(opportunity)
  end
end
