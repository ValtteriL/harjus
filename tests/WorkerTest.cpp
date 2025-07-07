/*
 * WorkerTest.cpp
 * Testing the Worker class.
 */

#include "Worker.h"
#include "Application_test.h"
#include "Balance.h"
#include "Execution.h"
#include "ExecutionReport.h"
#include "Position.h"
#include "PreciseNumber.h"
#include "PriceUpdate.h"
#include "ReservedTrades.h"
#include "TradeExecutionStatus.h"
#include <gmock/gmock.h>
#include <gtest/gtest.h>
#include <string>
#include <unordered_map>
#include <vector>

#include <gmock/gmock.h>
#include <gtest/gtest.h>

using ::testing::_;
using ::testing::Return;

class TestableWorker : public Worker {
public:
  TestableWorker(
      std::vector<std::vector<Trade>> &tradingPaths,
      boost::lockfree::spsc_queue<PriceUpdate> &priceUpdateQueue,
      boost::lockfree::spsc_queue<ExecutionReport> &executionReportQueue,
      IApplication &application, Balance &balance,
      std::unordered_map<std::string, PreciseNumber> relativeValues,
      const PreciseNumber &commission)
      : Worker(tradingPaths, priceUpdateQueue, executionReportQueue,
               application, balance, relativeValues, commission) {}

  // Expose private methods for testing
  void callProcessPriceUpdate(const PriceUpdate &update) {
    // Call the original processPriceUpdate method
    processPriceUpdate(update);
  }

  void callProcessReport(ExecutionReport *execReport) {
    processReport(execReport);
  }

  // Access to internal maps for advanced testing if needed
  [[nodiscard]] auto getExecutionsMap() const -> const auto & {
    return _executionsMap;
  }
  [[nodiscard]] auto getExecutionIdMap() const -> const auto & {
    return _executionIdMap;
  }
  [[nodiscard]] auto getPendingOrdersCount() const -> const auto & {
    return _pendingOrdersCount;
  }
};

/**
 * Test fixture for Engine.
 */

class WorkerTest : public testing::Test {

protected:
  static constexpr size_t kQueueSize = 1000;
  boost::lockfree::spsc_queue<ExecutionReport> executionReportQueue{kQueueSize};
  boost::lockfree::spsc_queue<PriceUpdate> priceUpdateQueue{kQueueSize};
  MockApplication mockApplication;
  Balance balance;
  ReservedTrades reservedTrades;
  std::unordered_map<std::string, Symbol> symbolsMap{};
  PreciseNumber startingAssetBudget{"1.0"};
  std::unordered_map<std::string, PreciseNumber> relativeValues{
      {"BTC", PreciseNumber{"1.0"}},
      {"ETH", PreciseNumber{"1.0"}},
      {"USDT", PreciseNumber{"1.0"}}};
  PreciseNumber commission{"0.001"};

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

  // simple triangular arbitrage
  // BTC -> ETH -> USDT -> BTC
  std::vector<Trade> trades{Trade{&symbols.at("ETHBTC"), Position::LONG},
                            Trade{&symbols.at("ETHUSDT"), Position::SHORT},
                            Trade{&symbols.at("USDTBTC"), Position::SHORT}};
  std::vector<std::vector<Trade>> tradingPaths{};
  TestableWorker worker;

  WorkerTest()
      : tradingPaths({trades}),
        worker(tradingPaths, priceUpdateQueue, executionReportQueue,
               mockApplication, balance, relativeValues, commission) {
    // Setup mock application behavior
    EXPECT_CALL(mockApplication, subscribeToSymbols(_))
        .WillRepeatedly(Return(true));

    // Setup initial balance
    balance.updateBalance("BTC", startingAssetBudget);
  }

  // Helper method to create a simple opportunity
  auto createSimpleOpportunity() -> Opportunity {

    // Create and store symbols properly
    symbolsMap.insert(
        {"ETHBTC", Symbol{"ETHBTC", "ETH", "BTC", PreciseNumber{"0.0001"},
                          PreciseNumber{"0.0001"}, PreciseNumber{"0.0001"}, 8,
                          8, PreciseNumber{"0.0"}, PreciseNumber{"0.0"},
                          PreciseNumber{"0.0"}, PreciseNumber{"0.0"}}});
    symbolsMap.insert(
        {"ETHUSDT", Symbol{"ETHUSDT", "ETH", "USDT", PreciseNumber{"0.0001"},
                           PreciseNumber{"0.0001"}, PreciseNumber{"0.0001"}, 8,
                           8, PreciseNumber{"0.0"}, PreciseNumber{"0.0"},
                           PreciseNumber{"0.0"}, PreciseNumber{"0.0"}}});

    // Setup trades using the stored symbols
    trades.emplace_back(&symbolsMap.at("ETHBTC"), Position::LONG);
    trades.emplace_back(&symbolsMap.at("ETHUSDT"), Position::SHORT);

    return {trades, PreciseNumber{"1"}, PreciseNumber{"0.001"}};
  }

  void verifyExecutionProperties(const Execution &execution,
                                 const PreciseNumber &startingAssetBudget,
                                 const PreciseNumber &profit,
                                 const PreciseNumber &initialBalance,
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
};

TEST_F(WorkerTest, detectsArbitrageOpportunity) {

  std::vector<PriceUpdate> updates{};
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
    worker.callProcessPriceUpdate(update);
  }

  // Trades should be reserved
  auto reservedTradesSet = reservedTrades.getReservedTrades();
  for (const auto &tradeVector : tradingPaths) {
    for (const auto &trade : tradeVector) {
      ASSERT_TRUE(reservedTradesSet.contains(trade.symbol()->symbol));
    }
  }

  // Expect calls to submitOrder for both trades in the execution
  EXPECT_CALL(mockApplication, submitOrder(_, "ETHBTC", PreciseNumber{"1"},
                                           PreciseNumber{"1"}, Position::LONG))
      .Times(1);
  EXPECT_CALL(mockApplication, submitOrder(_, "ETHUSDT", PreciseNumber{"1"},
                                           PreciseNumber{"1"}, Position::SHORT))
      .Times(1);
  EXPECT_CALL(mockApplication,
              submitOrder(_, "USDTBTC", PreciseNumber{"1"}, PreciseNumber{"10"},
                          Position::SHORT))
      .Times(1);
}

TEST_F(WorkerTest, processesFilledExecutionReportCompleted) {
  // Create an opportunity and execution
  auto opportunity = createSimpleOpportunity();
  auto execution = Execution(opportunity);

  // Expect calls to submitOrder for both trades in the execution upfront
  for (const auto &trade : opportunity.getTrades()) {
    EXPECT_CALL(mockApplication,
                submitOrder(_, trade.symbol()->symbol, trade.orderQty(),
                            trade.orderPrice(), trade.position()))
        .Times(1);
  }

  // Process the execution first
  worker.callProcessExecution(execution);

  std::unordered_map<std::string, PreciseNumber> feeDelta{
      {"BTC", PreciseNumber{"-0.1"}} // Example fee
  };

  // get all order IDs from the execution ID map as vector
  // need to do this because the map is modified in the loop
  std::vector<std::string> orderIds{};
  for (const auto &trade : worker.getExecutionIdMap()) {
    orderIds.push_back(trade.first);
  }

  for (const auto &orderId : orderIds) {

    // Insert a partial execution report (not full fill)
    // using negative values as the test opportunity has zero recvQty & usedQty
    ExecutionReport partialReport{orderId, TradeExecutionStatus::FILLED,
                                  PreciseNumber{"-1"}, PreciseNumber{"-1"},
                                  feeDelta};

    worker.callProcessReport(&partialReport);

    // Create a filled execution report for each trade
    ExecutionReport executionReport{orderId, TradeExecutionStatus::FILLED,
                                    PreciseNumber{"0.1"}, PreciseNumber{"0.2"},
                                    feeDelta};

    // Process the filled execution report
    worker.callProcessReport(&executionReport);
  }

  // Verify the balance is updated correctly
  // Initial BTC balance: 1.0
  // Fees: -0.2 BTC
  // 1st trade, spending: 0.1 BTC
  // Final BTC balance: 1.0 - 0.2 - 0.1 = 0.7
  //
  // Initial ETH balance: 0.0
  // 1st trade, receiving: 0.2 ETH
  // 2nd trade, spending: 0.1 ETH
  // Final ETH balance: 0.0 + 0.2 - 0.1 = 0.1
  //
  // Initial USDT balance: 0.0
  // 1st trade, no change
  // 2nd trade, receiving: 0.2 USDT
  // Final USDT balance: 0.0 + 0.2 = 0.2
  EXPECT_EQ(balance.getBalances().at("BTC"), PreciseNumber{"0.7"});
  EXPECT_EQ(balance.getBalances().at("USDT"), PreciseNumber{"0.2"});
  EXPECT_EQ(balance.getBalances().at("ETH"), PreciseNumber{"0.1"});
}

TEST_F(WorkerTest, processesExpiredExecutionReport) {
  // Create an opportunity and execution
  auto opportunity = createSimpleOpportunity();
  auto execution = Execution(opportunity);

  // Reserve the trades
  reservedTrades.reserveAll(opportunity.getTrades());

  // Process the execution first - expect calls for both trades
  EXPECT_CALL(mockApplication, submitOrder(_, _, _, _, _)).Times(2);
  worker.callProcessExecution(execution);

  // get any order ID from the map
  auto orderId = worker.getExecutionIdMap().begin()->first;

  std::unordered_map<std::string, PreciseNumber> feeDelta{};
  ExecutionReport executionReport{orderId, TradeExecutionStatus::EXPIRED,
                                  PreciseNumber{"0"}, PreciseNumber{"0"},
                                  feeDelta};

  worker.callProcessReport(&executionReport);

  // Verify the balance is unchanged
  EXPECT_EQ(balance.getBalances().at("BTC"), PreciseNumber{"1.0"});

  // Verify that trades are not released yet
  auto reservedTradesSet = reservedTrades.getReservedTrades();
  for (auto &trade : opportunity.getTrades()) {
    EXPECT_TRUE(reservedTradesSet.contains(trade.symbol()->symbol));
  }

  // process another report
  auto orderId2 = worker.getExecutionIdMap().begin()++->first;
  ExecutionReport executionReport2{orderId2, TradeExecutionStatus::EXPIRED,
                                   PreciseNumber{"0"}, PreciseNumber{"0"},
                                   feeDelta};

  worker.callProcessReport(&executionReport2);

  // Verify the balance is unchanged
  EXPECT_EQ(balance.getBalances().at("BTC"), PreciseNumber{"1.0"});

  // Verify that trades are released
  auto reservedTradesSetAfter = reservedTrades.getReservedTrades();
  for (auto &trade : opportunity.getTrades()) {
    EXPECT_FALSE(reservedTradesSetAfter.contains(trade.symbol()->symbol));
  }
}
