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
#include <gmock/gmock.h>
#include <gtest/gtest.h>
#include <string>
#include <unordered_map>
#include <vector>

class TestableEngine : public Engine {
public:
  TestableEngine(std::unordered_map<std::string, Symbol> &symbols,
                 std::vector<std::vector<Trade> *> &tradingPaths,
                 Balance &balance, ReservedTrades &reservedTrades,
                 boost::lockfree::spsc_queue<PriceUpdate> &priceUpdateQueue,
                 boost::lockfree::spsc_queue<Execution> &executionQueue,
                 std::unordered_map<std::string, PreciseNumber> relativeValues,
                 PreciseNumber commission)
      : Engine(symbols, tradingPaths, balance, reservedTrades, priceUpdateQueue,
               executionQueue, relativeValues, commission) {}

  void callProcessPriceUpdate(const PriceUpdate &update) {
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

  void verifyExecutionProperties(const Execution &execution,
                                 PreciseNumber startingAssetBudget,
                                 PreciseNumber profit,
                                 PreciseNumber initialBalance,
                                 const std::string &asset) {
    Execution execCopy = execution;

    // Starting asset balance should be reserved
    EXPECT_EQ(balance.getBalances().at(asset) + execution.getCapacity(),
              initialBalance);

    EXPECT_EQ(execCopy.getTrades().size(), 3);
    EXPECT_EQ(execution.getTotalProfit(), profit);
    EXPECT_EQ(execution.getCapacity(), startingAssetBudget);
    EXPECT_EQ(execution.getStartingAsset(), asset);
  }

  PreciseNumber startingAssetBudget{"1.0"};

  // Allocate symbols manually
  Symbol ethBtcSymbol{"ETHBTC",
                      "ETH",
                      "BTC",
                      PreciseNumber{"0.0001"},
                      PreciseNumber{"0.0001"},
                      PreciseNumber{"0.0001"},
                      8,
                      8,
                      PreciseNumber{"0.0"},
                      PreciseNumber{"0.0"},
                      PreciseNumber{"0.0"},
                      PreciseNumber{"0.0"}};
  Symbol ethUsdtSymbol{"ETHUSDT",
                       "ETH",
                       "USDT",
                       PreciseNumber{"0.0001"},
                       PreciseNumber{"0.0001"},
                       PreciseNumber{"0.0001"},
                       8,
                       8,
                       PreciseNumber{"0.0"},
                       PreciseNumber{"0.0"},
                       PreciseNumber{"0.0"},
                       PreciseNumber{"0.0"}};
  Symbol usdtBtcSymbol{"USDTBTC",
                       "USDT",
                       "BTC",
                       PreciseNumber{"0.0001"},
                       PreciseNumber{"0.0001"},
                       PreciseNumber{"0.0001"},
                       8,
                       8,
                       PreciseNumber{"0.0"},
                       PreciseNumber{"0.0"},
                       PreciseNumber{"0.0"},
                       PreciseNumber{"0.0"}};

  std::unordered_map<std::string, Symbol> symbols{{"ETHBTC", ethBtcSymbol},
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

  boost::lockfree::spsc_queue<Execution> executionQueue{1000};
  boost::lockfree::spsc_queue<PriceUpdate> priceUpdateQueue{1000};

  // simple triangular arbitrage
  // BTC -> ETH -> USDT -> BTC
  std::vector<Trade> trades{Trade{&symbols.at("ETHBTC"), Position::LONG},
                            Trade{&symbols.at("ETHUSDT"), Position::SHORT},
                            Trade{&symbols.at("USDTBTC"), Position::SHORT}};

  TestableEngine engine;
};

TEST_F(EngineTest, detectsArbitrageOpportunity) {

  std::vector<PriceUpdate> updates;
  updates.push_back(PriceUpdate{&symbols.at("ETHBTC"), PreciseNumber{"0"},
                                PreciseNumber{"1"}, PreciseNumber{"0"},
                                PreciseNumber{"100"}}); // BTC -> ETH 1:1
  updates.push_back(PriceUpdate{&symbols.at("ETHUSDT"), PreciseNumber{"1"},
                                PreciseNumber{"0"}, PreciseNumber{"1"},
                                PreciseNumber{"0"}}); // ETH -> USDT 1:1
  updates.push_back(PriceUpdate{&symbols.at("USDTBTC"), PreciseNumber{"10.0"},
                                PreciseNumber{"0"}, PreciseNumber{"1.0"},
                                PreciseNumber{"0"}}); // USDT -> BTC 1:10

  // Store the initial balance before processing updates
  PreciseNumber initialBalance = balance.getBalances().at("BTC");

  for (auto &update : updates) {
    engine.callProcessPriceUpdate(update);
  }

  // Verify execution is queued
  Execution execution;
  ASSERT_TRUE(executionQueue.pop(execution));
  ASSERT_TRUE(executionQueue.empty());

  // Trades should be reserved
  auto reservedTradesSet = reservedTrades.getReservedTrades();
  for (const auto &tradeVector : tradingPaths) {
    for (const auto &trade : *tradeVector) {
      ASSERT_TRUE(reservedTradesSet.contains(trade.symbol()->symbol));
    }
  }

  verifyExecutionProperties(execution, startingAssetBudget,
                            PreciseNumber{"8.997"}, initialBalance, "BTC");
}
