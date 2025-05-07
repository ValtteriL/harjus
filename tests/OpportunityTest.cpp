/*
 * OpportunityTest.cpp
 * Testing the Opportunity class.
 */

#include "Opportunity.h"
#include "Symbol.h"
#include "Trade.h"
#include <gtest/gtest.h>
#include <vector>

/**
 * @brief Test the update method of the Opportunity class.
 * This test checks if the update method correctly updates the total profit and
 * capacity based on the trades and the starting asset budget.
 */
TEST(OpportunityTest, update) {

  // simple triangular arbitrage
  // BTC -> ETH -> USDT -> BTC

  // BTC -> ETH 1:1
  Symbol symbol1{
      "BTCETH", // symbol;
      "BTC",    // baseAsset;
      "ETH",    // quoteAsset;
      1.0,      // bidPrice;
      0.0,      // askPrice;
      100.0,    // bidQty;
      0.0,      // askQty;
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
      1.0,       // bidPrice;
      0.0,       // askPrice;
      1.0,       // bidQty;
      0.0,       // askQty;
      0.0001,    // minNotional;
      0.0001,    // baseAssetIncrement;
      0.0001,    // quoteAssetIncrement;
      8,         // baseAssetPrecision;
      8          // quoteAssetPrecision;
  };

  // USDT -> BTC 1:10
  Symbol symbol3{
      "BTCUSDT", // symbol;
      "BTC",     // baseAsset;
      "USDT",    // quoteAsset;
      0.0,       // bidPrice;
      0.1,       // askPrice;
      0.0,       // bidQty;
      100.0,     // askQty;
      0.0001,    // minNotional;
      0.0001,    // baseAssetIncrement;
      0.0001,    // quoteAssetIncrement;
      8,         // baseAssetPrecision;
      8          // quoteAssetPrecision;
  };

  Trade trade1(&symbol1, Position::SHORT);
  Trade trade2(&symbol2, Position::SHORT);
  Trade trade3(&symbol3, Position::LONG);

  std::vector<Trade> trades{trade1, trade2, trade3};
  boost::multiprecision::cpp_dec_float_50 startingAssetBudget = 1.0;
  boost::multiprecision::cpp_dec_float_50 relativeValue = 1.0;
  boost::multiprecision::cpp_dec_float_50 commission = 0.001;

  Opportunity opportunity{trades, relativeValue, commission};

  // verify the initial state of the opportunity
  EXPECT_EQ(opportunity.getTotalProfit(), 0.0); // Default profit is 0
  EXPECT_EQ(opportunity.getStartingAsset(), trades.front().getUsedCurrency());
  EXPECT_EQ(opportunity.getCapacity(),
            boost::multiprecision::cpp_dec_float_50{100});

  // Update the opportunity with the starting asset budget
  opportunity.update(startingAssetBudget);

  // Check if the total profit is calculated correctly
  EXPECT_NEAR(opportunity.getTotalProfit().convert_to<double>(), 8.997, 1e-5);
  // Check if the capacity is calculated correctly
  EXPECT_NEAR(opportunity.getCapacity().convert_to<double>(),
              startingAssetBudget.convert_to<double>(), 1e-5);
  // Check if the starting asset is correct
  EXPECT_EQ(opportunity.getStartingAsset(), trades.front().getUsedCurrency());
}
