/*
 * ExecutionTest.cpp
 * Testing the Execution class.
 */

#include "Execution.h"
#include "Symbol.h"
#include "Trade.h"
#include <gtest/gtest.h>
#include <vector>

/**
 * @brief Test the update method of the Execution class.
 * This test checks if the update method correctly updates the total profit and
 * capacity based on the trades and the starting asset budget.
 */
TEST(ExecutionTest, update) {

  // simple triangular arbitrage
  // BTC -> ETH -> USDT -> BTC

  // BTC -> ETH 1:1
  Symbol symbol1{
      "BTCETH", // symbol;
      "BTC",    // baseAsset;
      "ETH",    // quoteAsset;
      0.0,      // bidPrice;
      1.0,      // askPrice;
      0.0,      // bidQty;
      100.0,    // askQty;
      0.0001,   // minNotional;
      0.0001,   // baseAssetIncrement;
      0.0001,   // quoteAssetIncrement;
      8,        // baseAssetPrecision;
      8         // quoteAssetPrecision;
  };

  // ETH -> USDT 1:1
  Symbol symbol2{
      "ETHUSDT", // symbol;
      "ETH",     // baseAsset;
      "USDT",    // quoteAsset;
      0.0,       // bidPrice;
      1.0,       // askPrice;
      0.0,       // bidQty;
      1.0,       // askQty;
      0.0001,    // minNotional;
      0.0001,    // baseAssetIncrement;
      0.0001,    // quoteAssetIncrement;
      8,         // baseAssetPrecision;
      8          // quoteAssetPrecision;
  };

  // USDT -> BTC 1:10
  Symbol symbol3{
      "USDTBTC", // symbol;
      "USDT",    // baseAsset;
      "BTC",     // quoteAsset;
      10.0,      // bidPrice;
      0.0,       // askPrice;
      1.0,       // bidQty;
      0.0,       // askQty;
      0.0001,    // minNotional;
      0.0001,    // baseAssetIncrement;
      0.0001,    // quoteAssetIncrement;
      8,         // baseAssetPrecision;
      8          // quoteAssetPrecision;
  };

  Trade trade1(symbol1, Position::LONG);
  Trade trade2(symbol2, Position::LONG);
  Trade trade3(symbol3, Position::SHORT);

  std::vector<Trade> trades{trade1, trade2, trade3};
  boost::multiprecision::cpp_dec_float_50 startingAssetBudget = 1.0;
  boost::multiprecision::cpp_dec_float_50 relativeValue = 1.0;
  boost::multiprecision::cpp_dec_float_50 commission = 0.001;

  Execution execution{trades, relativeValue, commission};

  // verify the initial state of the execution
  EXPECT_EQ(execution.getTotalProfit(), 0.0); // Default profit is 0
  EXPECT_EQ(execution.getStartingAsset(), trades.front().getUsedCurrency());
  EXPECT_EQ(execution.getCapacity(),
            boost::multiprecision::cpp_dec_float_50{100});

  // Update the execution with the starting asset budget
  execution.update(startingAssetBudget);

  // Check if the total profit is calculated correctly
  EXPECT_NEAR(execution.getTotalProfit().convert_to<double>(), 8.997, 1e-5);
  // Check if the capacity is calculated correctly
  EXPECT_EQ(execution.getCapacity(),
            boost::multiprecision::cpp_dec_float_50{startingAssetBudget});
  // Check if the starting asset is correct
  EXPECT_EQ(execution.getStartingAsset(), trades.front().getUsedCurrency());
}
