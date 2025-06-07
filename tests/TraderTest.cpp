/*
 * TraderTest.cpp
 * Testing the Trader.
 */

#include "Trader.h"
#include "Application_test.h"
#include "Balance.h"
#include "Execution.h"
#include "ExecutionReport.h"
#include "Opportunity.h"
#include "PreciseNumber.h"
#include "ReservedTrades.h"
#include "ThreadSafeQueue.h"
#include "TradeExecutionStatus.h"
#include <boost/lockfree/queue.hpp>
#include <gmock/gmock.h>
#include <gtest/gtest.h>
#include <semaphore>

using ::testing::_;
using ::testing::Return;

// TestableTrader class to expose private methods for testing
class TestableTrader : public Trader {
public:
  TestableTrader(ThreadSafeQueue<Execution> &executionQueue,
                 ThreadSafeQueue<ExecutionReport> &executionReportQueue,
                 IApplication &application, Balance &balance,
                 ReservedTrades &reservedTrades,
                 int orderSubmissionSleepMicroseconds = 500)
      : Trader(executionQueue, executionReportQueue, application, balance,
               reservedTrades, orderSubmissionSleepMicroseconds) {}

  // Expose private methods for testing
  void callProcessExecution(Execution execution) {
    processExecution(execution);
  }

  void callProcessReport(ExecutionReport *execReport) {
    processReport(execReport);
  }

  // Access to internal maps for advanced testing if needed
  const auto &getExecutionsMap() const { return _executionsMap; }
  const auto &getExecutionIdMap() const { return _executionIdMap; }
  const auto &getPendingOrdersCount() const { return _pendingOrdersCount; }
};

/**
 * Test fixture for Trader.
 */
class TraderTest : public testing::Test {
protected:
  TraderTest()
      : trader(executionQueue, executionReportQueue, mockApplication, balance,
               reservedTrades, 500) {
    // Setup mock application behavior
    EXPECT_CALL(mockApplication, subscribeToSymbols(_))
        .WillRepeatedly(Return(true));

    // Setup initial balance
    balance.updateBalance("BTC", PreciseNumber{"1.0"});
  }

  // Helper method to create a simple opportunity
  Opportunity createSimpleOpportunity() {
    // Create and store symbols properly
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

    symbolsMap["ETHBTC"] = ethBtcSymbol;
    symbolsMap["ETHUSDT"] = ethUsdtSymbol;

    // Setup trades using the stored symbols
    std::vector<Trade> *trades =
        new std::vector<Trade>{Trade{symbolsMap["ETHBTC"], Position::LONG},
                               Trade{symbolsMap["ETHUSDT"], Position::SHORT}};

    return Opportunity(*trades, PreciseNumber{"1"}, PreciseNumber{"0.001"});
  }

  std::binary_semaphore semaphore{0};
  ThreadSafeQueue<Execution> executionQueue{semaphore};
  ThreadSafeQueue<ExecutionReport> executionReportQueue{semaphore};
  MockApplication mockApplication;
  Balance balance;
  ReservedTrades reservedTrades;
  std::unordered_map<std::string, Symbol *> symbolsMap;
  TestableTrader trader;

  // Add destructor to clean up symbol pointers
  ~TraderTest() {
    for (auto &pair : symbolsMap) {
      delete pair.second;
    }
  }
};

TEST_F(TraderTest, processesExecutions) {
  // Create an opportunity and execution
  auto opportunity = createSimpleOpportunity();
  auto execution = Execution(opportunity);

  // Expect calls to submitOrder for both trades in the execution
  for (const auto &trade : opportunity.getTrades()) {
    EXPECT_CALL(mockApplication,
                submitOrder(_, trade.symbol()->symbol, trade.orderQty(),
                            trade.orderPrice(), trade.position()))
        .Times(1);
  }

  // Process the execution
  trader.callProcessExecution(execution);
}

TEST_F(TraderTest, processesFilledExecutionReportCompleted) {
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
  trader.callProcessExecution(execution);

  std::unordered_map<std::string, PreciseNumber> feeDelta{
      {"BTC", PreciseNumber{"-0.1"}} // Example fee
  };

  // get all order IDs from the execution ID map as vector
  // need to do this because the map is modified in the loop
  std::vector<std::string> orderIds;
  for (const auto &trade : trader.getExecutionIdMap()) {
    orderIds.push_back(trade.first);
  }

  for (const auto &orderId : orderIds) {

    // Insert a partial execution report (not full fill)
    // using negative values as the test opportunity has zero recvQty & usedQty
    ExecutionReport partialReport{orderId, TradeExecutionStatus::FILLED,
                                  PreciseNumber{"-1"}, PreciseNumber{"-1"},
                                  feeDelta};

    trader.callProcessReport(&partialReport);

    // Create a filled execution report for each trade
    ExecutionReport executionReport{orderId, TradeExecutionStatus::FILLED,
                                    PreciseNumber{"0.1"}, PreciseNumber{"0.2"},
                                    feeDelta};

    // Process the filled execution report
    trader.callProcessReport(&executionReport);
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
  EXPECT_EQ(balance.getBalance("BTC"), PreciseNumber{"0.7"});
  EXPECT_EQ(balance.getBalance("USDT"), PreciseNumber{"0.2"});
  EXPECT_EQ(balance.getBalance("ETH"), PreciseNumber{"0.1"});
}

TEST_F(TraderTest, processesExpiredExecutionReport) {
  // Create an opportunity and execution
  auto opportunity = createSimpleOpportunity();
  auto execution = Execution(opportunity);

  // Reserve the trades
  reservedTrades.reserve(opportunity.getTrades());

  // Process the execution first - expect calls for both trades
  EXPECT_CALL(mockApplication, submitOrder(_, _, _, _, _)).Times(2);
  trader.callProcessExecution(execution);

  // get any order ID from the map
  auto orderId = trader.getExecutionIdMap().begin()->first;

  std::unordered_map<std::string, PreciseNumber> feeDelta{};
  ExecutionReport executionReport{orderId, TradeExecutionStatus::EXPIRED,
                                  PreciseNumber{"0"}, PreciseNumber{"0"},
                                  feeDelta};

  trader.callProcessReport(&executionReport);

  // Verify the balance is unchanged (except maybe for fees)
  EXPECT_EQ(balance.getBalance("BTC"), PreciseNumber{"1.0"});

  // Verify that trades are released
  for (auto &trade : opportunity.getTrades()) {
    EXPECT_FALSE(reservedTrades.isReserved(trade));
  }
}
