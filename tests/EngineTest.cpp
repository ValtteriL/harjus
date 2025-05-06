/*
 * EngineTest.cpp
 * Testing the Engine class.
 */

#include "Engine.h"
#include "Balance.h"
#include "Execution.h"
#include "PriceUpdate.h"
#include "ReservedTrades.h"
#include <boost/lockfree/queue.hpp>
#include <gmock/gmock.h>
#include <gtest/gtest.h>
#include <string>
#include <unordered_map>
#include <vector>

class TestableEngine : public Engine {
public:
  TestableEngine(
      std::unordered_map<std::string, Symbol *> &symbols,
      std::vector<std::vector<Trade> *> &tradingPaths, Balance &balance,
      ReservedTrades &reservedTrades,
      boost::lockfree::queue<PriceUpdate *> &priceUpdateQueue,
      boost::lockfree::queue<Execution *> &executionQueue,
      std::unordered_map<std::string, boost::multiprecision::cpp_dec_float_50>
          relativeValues,
      boost::multiprecision::cpp_dec_float_50 commission)
      : Engine(symbols, tradingPaths, balance, reservedTrades, priceUpdateQueue,
               executionQueue, relativeValues, commission) {}

  void callProcessPriceUpdate(PriceUpdate *update) {
    // Call the original processPriceUpdate method
    processPriceUpdate(update);
  }
};

/**
 * Test fixture for Engine.
 */

class EngineTest : public testing::Test {
protected:
  EngineTest()
      : tradingPaths({&trades}),
        engine(symbols, tradingPaths, balance, reservedTrades, priceUpdateQueue,
               executionQueue, relativeValues, commission) {

    balance.updateBalance("BTC", startingAssetBudget);
  }

  boost::multiprecision::cpp_dec_float_50 startingAssetBudget = 1.0;

  // Allocate symbols manually
  Symbol *ethBtcSymbol = new Symbol{"ETHBTC", "ETH",  "BTC",  0.0,    0.0, 0.0,
                                    0.0,      0.0001, 0.0001, 0.0001, 8,   8};
  Symbol *ethUsdtSymbol =
      new Symbol{"ETHUSDT", "ETH",  "USDT", 0.0,    0.0, 0.0,
                 0.0,       0.0001, 0.0001, 0.0001, 8,   8};
  Symbol *usdtBtcSymbol =
      new Symbol{"USDTBTC", "USDT", "BTC",  0.0,    0.0, 0.0,
                 0.0,       0.0001, 0.0001, 0.0001, 8,   8};

  std::unordered_map<std::string, Symbol *> symbols{{"ETHBTC", ethBtcSymbol},
                                                    {"ETHUSDT", ethUsdtSymbol},
                                                    {"USDTBTC", usdtBtcSymbol}};
  std::vector<std::vector<Trade> *> tradingPaths;
  Balance balance;
  ReservedTrades reservedTrades;
  std::unordered_map<std::string, boost::multiprecision::cpp_dec_float_50>
      relativeValues{{"BTC", 1.0}, {"ETH", 1.0}, {"USDT", 1.0}};
  boost::multiprecision::cpp_dec_float_50 commission{0.001};

  boost::lockfree::queue<PriceUpdate *> priceUpdateQueue{1000};
  boost::lockfree::queue<Execution *> executionQueue{1000};

  // simple triangular arbitrage
  // BTC -> ETH -> USDT -> BTC
  std::vector<Trade> trades{Trade{*symbols["ETHBTC"], Position::LONG},
                            Trade{*symbols["ETHUSDT"], Position::SHORT},
                            Trade{*symbols["USDTBTC"], Position::SHORT}};

  TestableEngine engine;
};

TEST_F(EngineTest, detectsArbitrageOpportunity) {

  std::vector<PriceUpdate *> updates;
  updates.push_back(new PriceUpdate{"ETHBTC", 0, 1, 0, 100}); // BTC -> ETH 1:1
  updates.push_back(new PriceUpdate{"ETHUSDT", 1, 0, 1, 0});  // ETH -> USDT 1:1
  updates.push_back(
      new PriceUpdate{"USDTBTC", 10.0, 0, 1.0, 0}); // USDT -> BTC 1:10

  for (auto update : updates) {
    engine.callProcessPriceUpdate(update);
  }

  // Verify execution is queued
  Execution *execution = nullptr;
  ASSERT_TRUE(executionQueue.pop(execution));

  EXPECT_EQ(execution->getTrades().size(), 3);

  // Check if the total profit is calculated correctly
  EXPECT_NEAR(execution->getTotalProfit().convert_to<double>(), 8.997, 1e-5);
  // Check if the capacity is calculated correctly
  EXPECT_EQ(execution->getCapacity(),
            boost::multiprecision::cpp_dec_float_50{startingAssetBudget});
  // Check if the starting asset is correct
  EXPECT_EQ(execution->getStartingAsset(), "BTC");
}
