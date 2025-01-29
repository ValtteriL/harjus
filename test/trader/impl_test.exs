defmodule Trader.ImplTest do
  @moduledoc "Tests for Impl"

  use ExUnit.Case, async: true
  use PropCheck
  alias Types.TradeReport
  alias Trader.Impl

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  property "succeeds when balace and free symbols" do
    forall {opportunity, balances} <- opportunity_and_balances do

      # setup mocks
      Balance.Exchange.TestMock
      |> expect(:get_balances, fn -> balances end)

      Trader.TradeClient.Exchange.TestMock
      |> expect(:new, fn -> :ok end)
      |> expect(:market_order, fn trading_symbol, quantity -> %TradeReport{
        # TODO
      } end)

      # init
      Impl.new()

      assert :ok == Impl.execute_opportunity(opportunity)
    end
  end

  property "fails if any symbol in path already reserved" do
    fails(forall()) do
    end
  end

  property "fails if no balance to reserve" do
  end

  ## Generators ##

  defp opportunity_and_balances do
    let [opportunity <- opportunity(), balances <- balances(^opportunity)] do
      {opportunity, balances}
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

  defp balances(%Opportunity{path: path}) do
    assets = path |> Enum.map(fn p -> p.quote_asset end) |> Enum.uniq()

    # TODO: set balances

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
    let [symbol <- non_empty_string(), position <- union([:long, :short]), base_asset <- non_empty_string(), quote_asset <- non_empty_string()] do
      %TradingSymbol{
        symbol: symbol,
        position: position,
        base_asset: base_asset,
        quote_asset: quote_asset
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
