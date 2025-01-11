defmodule PortfolioManager.TradingFeeCalculatorTest do
  @moduledoc "Tests for TradingFeeCalculator"

  alias PortfolioManager.TradingFeeCalculator

  use ExUnit.Case
  doctest TradingFeeCalculator

  test "calculates correct trading fee" do
    commission_percentage = 0.1

    commission =
      TradingFeeCalculator.total_commission_percentage(
        [
          %TradingSymbol{
            symbol: "BTCUSDT",
            position: :long,
            base_asset: "BTC",
            quote_asset: "USDT"
          },
          %TradingSymbol{
            symbol: "USDTBTC",
            position: :long,
            base_asset: "USDT",
            quote_asset: "BTC"
          }
        ],
        commission_percentage
      )

    assert commission == 2 * commission_percentage
  end
end
