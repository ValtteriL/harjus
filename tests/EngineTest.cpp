/*
 * EngineTest.cpp
 * Testing the reserved symbols.
 */

#include "Engine.h"
#include "Balance.h"
#include "Execution.h"
#include "Opportunity.h"
#include "ReservedTrades.h"
#include <boost/lockfree/queue.hpp>
#include <gmock/gmock.h>
#include <gtest/gtest.h>
#include <string>
#include <unordered_map>

/**
 * Test fixture for Engine.
 */

class EngineTest : public testing::Test {
protected:
  EngineTest() {

    std::unordered_map<std::string, Symbol> symbols;
    std::vector<std::vector<Trade> *> tradingPaths;
    Balance balance;
    ReservedTrades reservedTrades;
    boost::lockfree::queue<PriceUpdate *> priceUpdateQueue;
    boost::lockfree::queue<Execution *> executionQueue;

    std::unordered_map<std::string, boost::multiprecision::cpp_dec_float_50>
        relativeValues;
    boost::multiprecision::cpp_dec_float_50 commission;

    Engine engine{symbols,        tradingPaths,     balance,
                  reservedTrades, priceUpdateQueue, executionQueue,
                  relativeValues, commission};
  }

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
  Trade trade1{symbol, Position::LONG};
  Trade trade2{symbol, Position::LONG};
  Trade trade3{symbol, Position::SHORT};
  // Engine engine;
};

TEST_F(EngineTest, checkReserveCheckReleaseCheck) {

  // TODO: updates are removed from the queue
  EXPECT_FALSE(true);

  // TODO: execution is queued
  EXPECT_FALSE(true);
}
