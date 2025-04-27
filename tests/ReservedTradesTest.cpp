/*
 * ReservedTradesTest.cpp
 * Testing the reserved symbols.
 */

#include "ReservedTrades.h"
#include "Trade_test.h"
#include <gmock/gmock.h>
#include <gtest/gtest.h>
using ::testing::Return;
using ::testing::ReturnRef;

/**
 * Test fixture for ReservedTrades.
 */

class ReservedTradesTest : public testing::Test {
protected:
  ReservedTradesTest() {
    // trade1 and trade2 are identical trades
    // trade3 is a different (different position)

    EXPECT_CALL(trade1, getSymbol()).WillRepeatedly(ReturnRef(symbol));
    EXPECT_CALL(trade1, getPosition()).WillRepeatedly(Return(Position::LONG));

    EXPECT_CALL(trade2, getSymbol()).WillRepeatedly(ReturnRef(symbol));
    EXPECT_CALL(trade2, getPosition()).WillRepeatedly(Return(Position::LONG));

    EXPECT_CALL(trade3, getSymbol()).WillRepeatedly(ReturnRef(symbol));
    EXPECT_CALL(trade3, getPosition()).WillRepeatedly(Return(Position::SHORT));
  }

  Symbol symbol;
  MockTrade trade1;
  MockTrade trade2;
  MockTrade trade3;
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
