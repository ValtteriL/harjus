/*
 * OpportunityTest.cpp
 * Testing the Opportunity class.
 */

#include "Opportunity.h"
#include "Position.h"
#include "PreciseNumber.h"
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
  PreciseNumber startingAssetBudget = 1.0;
  PreciseNumber relativeValue = 1.0;
  PreciseNumber commission = 0.001;

  Opportunity opportunity{trades, relativeValue, commission};

  // verify the initial state of the opportunity
  EXPECT_EQ(opportunity.getTotalProfit(), 0.0); // Default profit is 0
  EXPECT_EQ(opportunity.getStartingAsset(), trades.front().usedCurrency());
  EXPECT_EQ(opportunity.getCapacity(), PreciseNumber{100});

  // Update the opportunity with the starting asset budget
  opportunity.update(startingAssetBudget);

  // Check if the total profit is calculated correctly
  EXPECT_EQ(opportunity.getTotalProfit(), PreciseNumber{8.996997});
  // Check if the capacity is calculated correctly
  EXPECT_EQ(opportunity.getCapacity(), startingAssetBudget);
  // Check if the starting asset is correct
  EXPECT_EQ(opportunity.getStartingAsset(), trades.front().usedCurrency());

  // Check orderQty is a multiple of baseAssetIncrement and minNotional
  // Check notional is at least minNotional, or zero if orderQty is zero
  for (const auto &trade : opportunity.getTrades()) {
    const Symbol *sym = trade.symbol();
    auto orderQty = trade.orderQty();
    auto increment = sym->baseAssetIncrement;
    auto minNotional = sym->minNotional;
    auto price = trade.orderPrice();

    // Check orderQty is a multiple of baseAssetIncrement (within tolerance)
    auto baseassetincrementremainder = PreciseNumber::fmod(orderQty, increment);
    ASSERT_EQ(baseassetincrementremainder, 0.0);

    // Check orderQty is a multiple of minNotional (within tolerance)
    auto minNotionalRemainder = PreciseNumber::fmod(orderQty, minNotional);
    ASSERT_EQ(minNotionalRemainder, 0.0);

    // Check notional is at least minNotional (or zero if orderQty is zero)
    auto notional = orderQty * price;
    if (orderQty > 0) {
      ASSERT_GE(notional, minNotional);
    } else {
      ASSERT_EQ(notional, 0.0);
    }
  }
}
