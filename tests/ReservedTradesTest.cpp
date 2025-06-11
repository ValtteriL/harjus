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
      "BTCETH",                // symbol;
      "BTC",                   // baseAsset;
      "ETH",                   // quoteAsset;
      PreciseNumber{"0.0001"}, // minNotional;
      PreciseNumber{"0.0001"}, // baseAssetIncrement;
      PreciseNumber{"0.0001"}, // quoteAssetIncrement;
      8,                       // baseAssetPrecision;
      8,                       // quoteAssetPrecision;
      PreciseNumber{"0.0"},    // bidPrice;
      PreciseNumber{"1.0"},    // askPrice;
      PreciseNumber{"0.0"},    // bidQty;
      PreciseNumber{"100.0"}   // askQty;
  };
  Trade trade1{&symbol, Position::LONG};
  Trade trade2{&symbol, Position::LONG};
  Trade trade3{&symbol, Position::SHORT};
  ReservedTrades reservedTrades;
};

TEST_F(ReservedTradesTest, checkReserveCheckReleaseCheck) {
  EXPECT_FALSE(reservedTrades.isReserved(trade1));

  std::vector<Trade> trades{trade1};
  reservedTrades.reserve(trades);
  EXPECT_TRUE(reservedTrades.isReserved(trade1));

  reservedTrades.release(trade1);
  EXPECT_FALSE(reservedTrades.isReserved(trade1));
}

TEST_F(ReservedTradesTest, reserveCheckIdenticalTrade) {
  std::vector<Trade> trades{trade1};
  reservedTrades.reserve(trades);
  EXPECT_TRUE(reservedTrades.isReserved(trade2));
}

TEST_F(ReservedTradesTest, reserveCheckDifferentTrade) {
  std::vector<Trade> trades{trade1};
  reservedTrades.reserve(trades);
  EXPECT_FALSE(reservedTrades.isReserved(trade3));
}

TEST_F(ReservedTradesTest, releaseAll) {
  std::vector<Trade> trades{trade1, trade2};
  reservedTrades.reserve(trades);

  EXPECT_TRUE(reservedTrades.isReserved(trade1));
  EXPECT_TRUE(reservedTrades.isReserved(trade2));

  std::vector<StaticTrade> staticTrades{trade1, trade2};

  reservedTrades.releaseAll(staticTrades);

  EXPECT_FALSE(reservedTrades.isReserved(trade1));
  EXPECT_FALSE(reservedTrades.isReserved(trade2));
}

// test isReserved with vector of trades
TEST_F(ReservedTradesTest, isReservedWithVector) {

  std::vector<Trade> trades{trade1, trade2, trade3};

  EXPECT_FALSE(reservedTrades.isReserved(trades));

  std::vector<Trade> reserveTrades{trade1};
  reservedTrades.reserve(reserveTrades);

  EXPECT_TRUE(reservedTrades.isReserved(trades));
}