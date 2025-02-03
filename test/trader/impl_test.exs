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
    forall [opportunity, trade_report] <-
             [
               opportunity_with_uniq_symbols(),
               trade_report()
             ] do
      # setup mocks
      Trader.Balance.TestMock
      |> stub(:update, fn _asset, _amount -> :ok end)
      |> expect(:reserve_upto, fn _asset, _amount, _increment, _precision -> Decimal.new(1) end)

      Trader.TradeClient.Exchange.TestMock
      |> expect(:new, fn -> :ok end)
      |> expect(:market_order, Enum.count(opportunity.path), fn _trading_symbol, _quantity ->
        trade_report
      end)

      # init
      Impl.new()

      assert :ok == Impl.execute_opportunity(opportunity)
    end
  end

  property "fails if any symbol in path already reserved" do
    forall [opportunity, trade_report] <-
             [
               opportunity_with_duplicate_symbols(),
               trade_report()
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
    forall opportunity <- opportunity_with_uniq_symbols() do
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

  ## Generators ##

  defp opportunity_with_uniq_symbols do
    let opportunity <- opportunity() do
      # make symbols unique
      uniq_path = opportunity.path |> Enum.uniq_by(fn p -> p.symbol end)
      %{opportunity | path: uniq_path}
    end
  end

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
      path
    end
  end

  defp trading_symbol do
    let [
      symbol <- non_empty_string(),
      position <- union([:long, :short]),
      base_asset <- non_empty_string(),
      quote_asset <- non_empty_string()
    ] do
      %TradingSymbol{
        symbol: symbol,
        position: position,
        base_asset: base_asset,
        quote_asset: quote_asset,
        quote_asset_increment: Decimal.from_float(0.01),
        quote_asset_precision: 8
      }
    end
  end

  defp trade_report do
    let([
      symbol <- non_empty_string(),
      position <- union([:long, :short]),
      qty_base <- pos_decimal(),
      qty_quote <- pos_decimal(),
      qty_fee <- pos_decimal(),
      fee_currency <- non_empty_string()
    ]) do
      %TradeReport{
        symbol: symbol,
        position: position,
        quantity_base: qty_base,
        quantity_quote: qty_quote,
        quantity_fee: qty_fee,
        fee_currency: fee_currency
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
