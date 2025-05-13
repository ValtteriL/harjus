/*
 * ReservedTradesTest.cpp
 * Testing the reserved symbols.
 */

#include "ReservedTrades.h"
#include "StaticTrade.h"
#include <gmock/gmock.h>
#include <gtest/gtest.h>
using ::testing::Return;
using ::testing::ReturnRef;

/**
 * Test fixture for ReservedTrades.
 */

class ReservedTradesTest : public testing::Test {
protected:
  ReservedTradesTest() {}

  // trade1 and trade2 are identical trades
  // trade3 is a different (different position)
  Symbol symbol{
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
  Trade trade1{&symbol, Position::LONG};
  Trade trade2{&symbol, Position::LONG};
  Trade trade3{&symbol, Position::SHORT};
  ReservedTrades reservedTrades;
};

TEST_F(ReservedTradesTest, checkReserveCheckReleaseCheck) {
  EXPECT_FALSE(reservedTrades.isReserved(trade1));

  reservedTrades.reserve(trade1);
  EXPECT_TRUE(reservedTrades.isReserved(trade1));

  reservedTrades.release(trade1);
  EXPECT_FALSE(reservedTrades.isReserved(trade1));
}

TEST_F(ReservedTradesTest, reserveCheckIdenticalTrade) {
  reservedTrades.reserve(trade1);
  EXPECT_TRUE(reservedTrades.isReserved(trade2));
}

TEST_F(ReservedTradesTest, reserveCheckDifferentTrade) {
  reservedTrades.reserve(trade1);
  EXPECT_FALSE(reservedTrades.isReserved(trade3));
}

TEST_F(ReservedTradesTest, releaseAll) {
  reservedTrades.reserve(trade1);
  reservedTrades.reserve(trade2);

  EXPECT_TRUE(reservedTrades.isReserved(trade1));
  EXPECT_TRUE(reservedTrades.isReserved(trade2));

  std::vector<StaticTrade> trades{trade1, trade2};

  reservedTrades.releaseAll(trades);

  EXPECT_FALSE(reservedTrades.isReserved(trade1));
  EXPECT_FALSE(reservedTrades.isReserved(trade2));
}

// test isReserved with vector of trades
TEST_F(ReservedTradesTest, isReservedWithVector) {

  std::vector<Trade> trades{trade1, trade2, trade3};

  EXPECT_FALSE(reservedTrades.isReserved(trades));

  reservedTrades.reserve(trade1);

  EXPECT_TRUE(reservedTrades.isReserved(trades));
}