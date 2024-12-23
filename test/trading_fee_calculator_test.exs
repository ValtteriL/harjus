defmodule TradingFeeCalculatorTest do
  use ExUnit.Case
  doctest TradingFeeCalculator

  test "calculates correct trading fee" do
    tax_comm_taker = 0.1
    tax_comm_buyer = 0.2
    tax_comm_seller = 0.51
    std_comm_taker = 0.3
    std_comm_buyer = 0.4
    std_comm_seller = 0.532
    discount = 0.1123

    commission =
      TradingFeeCalculator.total_commission_percentage(
        [{"BTCUSDT", :long}, {"USDTBTC", :short}],
        std_comm_taker,
        std_comm_buyer,
        std_comm_seller,
        tax_comm_taker,
        tax_comm_buyer,
        tax_comm_seller,
        discount
      )

    assert commission ==
             (std_comm_buyer + std_comm_taker) * (1.0 - discount) + tax_comm_buyer +
               tax_comm_taker +
               (std_comm_taker + std_comm_seller) * (1.0 - discount) + tax_comm_seller +
               tax_comm_taker
  end

  test "calculates correct trading fee when discount is zero" do
    tax_comm_taker = 0.1
    tax_comm_buyer = 0.2
    std_comm_taker = 0.3
    std_comm_buyer = 0.4

    commission =
      TradingFeeCalculator.total_commission_percentage(
        [{"BTCUSDT", :long}, {"USDTBTC", :long}],
        std_comm_taker,
        std_comm_buyer,
        0.3,
        tax_comm_taker,
        tax_comm_buyer,
        0.6,
        0.0
      )

    assert commission == 2 * (std_comm_taker + tax_comm_taker + std_comm_buyer + tax_comm_buyer)
  end

  test "calculates correct trading fee when all fees are zero" do
    commission =
      TradingFeeCalculator.total_commission_percentage(
        [{"BTCUSDT", :long}, {"USDTBTC", :long}],
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0
      )

    assert commission == 0.0
  end

  test "calculates correct trading fee when discount is 100%" do
    tax_comm_taker = 0.1
    tax_comm_buyer = 0.2

    commission =
      TradingFeeCalculator.total_commission_percentage(
        [{"BTCUSDT", :long}, {"USDTBTC", :long}],
        0.1,
        0.2,
        0.3,
        tax_comm_taker,
        tax_comm_buyer,
        0.6,
        1.0
      )

    assert commission == 2 * (tax_comm_taker + tax_comm_buyer)
  end
end
