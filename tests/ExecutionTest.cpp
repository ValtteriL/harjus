/*
 * ExecutionTest.cpp
 * Testing the Execution class.
 */

#include "Execution.h"
#include "Trade.h"
#include "Trade_test.h"
#include <gtest/gtest.h>
#include <vector>

TEST(ExecutionTest, defaultConstructor) {

  std::string startingAsset = "BTC";
  boost::multiprecision::cpp_dec_float_50 relativeValue = 1;
  boost::multiprecision::cpp_dec_float_50 commission = 1;

  Symbol symbol;
  symbol.quoteAsset = startingAsset;
  Trade trade(symbol, Position::LONG);

  std::vector<Trade> trades{trade};

  Execution execution{trades, relativeValue, commission};

  EXPECT_EQ(execution.getTotalProfit(), 0.0); // Default profit is 0
  EXPECT_EQ(execution.getStartingAsset(), startingAsset);
  EXPECT_EQ(execution.getCapacity(), 0.0); // Cap is 0 as not set in symbol
}
