defmodule Trader.ImplTest do
  @moduledoc "Tests for Impl"

  use ExUnit.Case
  use PropCheck

  alias Trader.Error.InsufficientBalanceError
  alias Trader.Error.SymbolAlreadyReservedError
  alias Trader.Impl
  alias Types.Opportunity
  alias Types.TradeReport
  alias Types.TradingSymbol
  require Decimal

  import Mox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  # turn off logging
  @moduletag :capture_log

  property "succeeds when balace and free symbols" do
    forall opportunity <- opportunity() do
      # setup mocks
      Trader.Balance.TestMock
      |> stub(:update, fn _asset, _amount -> :ok end)
      |> expect(:reserve_upto, fn _asset, _amount, _increment, _precision -> Decimal.new(1) end)

      Trader.TradeClient.Exchange.TestMock
      |> expect(:new, fn -> :ok end)
      |> expect(:market_order, Enum.count(opportunity.path), fn trading_symbol, _quantity ->
        trade_report_for_symbol(trading_symbol)
      end)

      # init
      Impl.new()

      assert :ok == Impl.execute_opportunity(opportunity)
    end
  end

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

  property "fails if no balance to reserve" do
    forall opportunity <- opportunity() do
      # setup mocks
      Trader.Balance.TestMock
      |> stub(:update, fn _asset, _amount -> :ok end)
      |> expect(:reserve_upto, fn _asset, _amount, _increment, _precision ->
        Decimal.from_float(0.0)
      end)

      Trader.TradeClient.Exchange.TestMock
      |> expect(:new, fn -> :ok end)

      # init
      Impl.new()

      raises_correct_error =
        try do
          Impl.execute_opportunity(opportunity)
        rescue
          InsufficientBalanceError -> true
        else
          _ -> false
        end

      assert raises_correct_error
    end
  end

  defp trade_report_for_symbol(%TradingSymbol{position: position, symbol: symbol}) do
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
    }
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
    let path <- non_empty(list(trading_symbol())) do
      first_base_asset = Enum.at(path, 0).base_asset

      path
      # make symbols in path unique
      |> Enum.uniq_by(fn p -> p.symbol end)
      # make sure the next quote asset is the same as the previous base asset
      |> Enum.map_reduce(first_base_asset, fn ts, prev_base_asset ->
        new_ts = ts |> Map.put(:quote_asset, prev_base_asset)
        {new_ts, ts.base_asset}
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
        quote_asset_increment: Decimal.from_float(0.01),
        quote_asset_precision: 8,
        min_notional: min_notional
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
end
