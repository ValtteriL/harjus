/*
 * EngineTest.cpp
 * Testing the Engine class.
 */

#include "Engine.h"
#include "Balance.h"
#include "Execution.h"
#include "PreciseNumber.h"
#include "PriceUpdate.h"
#include "ReservedTrades.h"
#include "ThreadSafeQueue.h"
#include <boost/lockfree/queue.hpp>
#include <gmock/gmock.h>
#include <gtest/gtest.h>
#include <semaphore>
#include <string>
#include <unordered_map>
#include <vector>

class TestableEngine : public Engine {
public:
  TestableEngine(std::unordered_map<std::string, Symbol *> &symbols,
                 std::vector<std::vector<Trade> *> &tradingPaths,
                 Balance &balance, ReservedTrades &reservedTrades,
                 boost::lockfree::queue<PriceUpdate *> &priceUpdateQueue,
                 ThreadSafeQueue<Execution> &executionQueue,
                 std::unordered_map<std::string, PreciseNumber> relativeValues,
                 PreciseNumber commission)
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

  PreciseNumber startingAssetBudget{"1.0"};

  // Allocate symbols manually
  Symbol *ethBtcSymbol = new Symbol{"ETHBTC",
                                    "ETH",
                                    "BTC",
                                    PreciseNumber{"0.0"},
                                    PreciseNumber{"0.0"},
                                    PreciseNumber{"0.0"},
                                    PreciseNumber{"0.0"},
                                    PreciseNumber{"0.0001"},
                                    PreciseNumber{"0.0001"},
                                    PreciseNumber{"0.0001"},
                                    8,
                                    8};
  Symbol *ethUsdtSymbol = new Symbol{"ETHUSDT",
                                     "ETH",
                                     "USDT",
                                     PreciseNumber{"0.0"},
                                     PreciseNumber{"0.0"},
                                     PreciseNumber{"0.0"},
                                     PreciseNumber{"0.0"},
                                     PreciseNumber{"0.0001"},
                                     PreciseNumber{"0.0001"},
                                     PreciseNumber{"0.0001"},
                                     8,
                                     8};
  Symbol *usdtBtcSymbol = new Symbol{"USDTBTC",
                                     "USDT",
                                     "BTC",
                                     PreciseNumber{"0.0"},
                                     PreciseNumber{"0.0"},
                                     PreciseNumber{"0.0"},
                                     PreciseNumber{"0.0"},
                                     PreciseNumber{"0.0001"},
                                     PreciseNumber{"0.0001"},
                                     PreciseNumber{"0.0001"},
                                     8,
                                     8};

  std::unordered_map<std::string, Symbol *> symbols{{"ETHBTC", ethBtcSymbol},
                                                    {"ETHUSDT", ethUsdtSymbol},
                                                    {"USDTBTC", usdtBtcSymbol}};
  std::vector<std::vector<Trade> *> tradingPaths;
  Balance balance;
  ReservedTrades reservedTrades;
  std::unordered_map<std::string, PreciseNumber> relativeValues{
      {"BTC", PreciseNumber{"1.0"}},
      {"ETH", PreciseNumber{"1.0"}},
      {"USDT", PreciseNumber{"1.0"}}};
  PreciseNumber commission{"0.001"};

  std::binary_semaphore semaphore{0};
  ThreadSafeQueue<Execution> executionQueue{semaphore};
  boost::lockfree::queue<PriceUpdate *> priceUpdateQueue{1000};

  // simple triangular arbitrage
  // BTC -> ETH -> USDT -> BTC
  std::vector<Trade> trades{Trade{symbols["ETHBTC"], Position::LONG},
                            Trade{symbols["ETHUSDT"], Position::SHORT},
                            Trade{symbols["USDTBTC"], Position::SHORT}};

  TestableEngine engine;
};

TEST_F(EngineTest, detectsArbitrageOpportunity) {

  std::vector<PriceUpdate *> updates;
  updates.push_back(new PriceUpdate{"ETHBTC", PreciseNumber{"0"},
                                    PreciseNumber{"1"}, PreciseNumber{"0"},
                                    PreciseNumber{"100"}}); // BTC -> ETH 1:1
  updates.push_back(new PriceUpdate{"ETHUSDT", PreciseNumber{"1"},
                                    PreciseNumber{"0"}, PreciseNumber{"1"},
                                    PreciseNumber{"0"}}); // ETH -> USDT 1:1
  updates.push_back(new PriceUpdate{"USDTBTC", PreciseNumber{"10.0"},
                                    PreciseNumber{"0"}, PreciseNumber{"1.0"},
                                    PreciseNumber{"0"}}); // USDT -> BTC 1:10

  for (auto update : updates) {
    engine.callProcessPriceUpdate(update);
  }

  // Verify execution is queued
  Execution execution;
  ASSERT_TRUE(executionQueue.try_pop(execution));

  EXPECT_EQ(execution.getTrades().size(), 3);

  // Check if the total profit is calculated correctly
  EXPECT_EQ(execution.getTotalProfit(), PreciseNumber{"8.996996999"});
  // Check if the capacity is calculated correctly

  EXPECT_EQ(execution.getCapacity(), PreciseNumber{startingAssetBudget});
  // Check if the starting asset is correct
  EXPECT_EQ(execution.getStartingAsset(), "BTC");
}
