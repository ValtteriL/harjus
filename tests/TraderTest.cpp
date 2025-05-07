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
                 ReservedTrades &reservedTrades)
      : Trader(executionQueue, executionReportQueue, application, balance,
               reservedTrades) {}

  // Expose private methods for testing
  void callProcessExecution(Execution &execution) {
    processExecution(execution);
  }

  void callProcessReport(ExecutionReport &execReport) {
    processReport(execReport);
  }
};

/**
 * Test fixture for Trader.
 */
class TraderTest : public testing::Test {
protected:
  TraderTest()
      : trader(executionQueue, executionReportQueue, mockApplication, balance,
               reservedTrades) {
    // Setup mock application behavior
    EXPECT_CALL(mockApplication, subscribeToSymbols(_))
        .WillRepeatedly(Return(true));

    // Setup initial balance
    balance.updateBalance("BTC", 1.0);
  }

  // Helper method to create a simple opportunity
  Opportunity createSimpleOpportunity() {
    // Create and store symbols properly
    Symbol *ethBtcSymbol =
        new Symbol{"ETHBTC", "ETH",  "BTC",  0.0,    0.0, 0.0,
                   0.0,      0.0001, 0.0001, 0.0001, 8,   8};
    Symbol *ethUsdtSymbol =
        new Symbol{"ETHUSDT", "ETH",  "USDT", 0.0,    0.0, 0.0,
                   0.0,       0.0001, 0.0001, 0.0001, 8,   8};

    symbolsMap["ETHBTC"] = ethBtcSymbol;
    symbolsMap["ETHUSDT"] = ethUsdtSymbol;

    // Setup trades using the stored symbols
    std::vector<Trade> *trades =
        new std::vector<Trade>{Trade{symbolsMap["ETHBTC"], Position::LONG},
                               Trade{symbolsMap["ETHUSDT"], Position::SHORT}};

    return Opportunity(*trades, 1, 0.001);
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

  // Expect a call to submitOrder with the correct parameters
  EXPECT_CALL(mockApplication,
              submitOrder(_, "ETHBTC",
                          opportunity.getTrades().front().getOrderQty(),
                          opportunity.getTrades().front().getOrderPrice(),
                          Position::LONG))
      .Times(1);

  // Process the execution
  trader.callProcessExecution(&execution);

  // Clean up - don't delete execution here, it's stored in the executionsMap
}

TEST_F(TraderTest, processesFilledExecutionReportCompleted) {
  // Create an opportunity and execution
  auto opportunity = createSimpleOpportunity();
  auto execution = Execution(opportunity);

  // Process the execution first
  EXPECT_CALL(mockApplication,
              submitOrder(_, "ETHBTC",
                          opportunity.getTrades().front().getOrderQty(),
                          opportunity.getTrades().front().getOrderPrice(),
                          Position::LONG))
      .Times(1);
  trader.callProcessExecution(&execution);

  // Now create an execution report for the completed trade
  std::string id = "0"; // Generated ID in Trader::processExecution starts at 0
  std::unordered_map<std::string, boost::multiprecision::cpp_dec_float_50>
      feeDelta{
          {"BTC", boost::multiprecision::cpp_dec_float_50(-0.1)} // Example fee
      };

  auto executionReport =
      ExecutionReport(id, TradeExecutionStatus::FILLED, feeDelta);

  // Since there is still one more trade in the execution, expect another
  // submitOrder
  EXPECT_CALL(mockApplication,
              submitOrder(id, "ETHUSDT",
                          opportunity.getTrades().back().getOrderQty(),
                          opportunity.getTrades().back().getOrderPrice(),
                          Position::SHORT))
      .Times(1);

  // Process the report
  trader.callProcessReport(&executionReport);

  // Process another report to complete the execution
  auto finalReport =
      ExecutionReport(id, TradeExecutionStatus::FILLED, feeDelta);
  trader.callProcessReport(&finalReport);

  // Verify the balance is updated correctly
  // Initial balance: 1.0 BTC
  // Fees: -0.2 BTC
  // Final balance: 1.0 - 0.2 = 0.8 BTC
  // other assets should be unchanged
  EXPECT_NEAR(balance.getBalance("BTC").convert_to<double>(), 0.8, 1e-5);
  EXPECT_NEAR(balance.getBalance("USDT").convert_to<double>(), 0, 1e-5);
  EXPECT_NEAR(balance.getBalance("ETH").convert_to<double>(), 0, 1e-5);
}

TEST_F(TraderTest, processesExpiredExecutionReport) {
  // Create an opportunity and execution
  auto opportunity = createSimpleOpportunity();
  auto execution = Execution(opportunity);

  // Reserve the trades
  for (auto &trade : execution.getOriginalTrades()) {
    reservedTrades.reserve(trade);
  }

  // Process the execution first
  EXPECT_CALL(mockApplication, submitOrder(_, _, _, _, _)).Times(1);
  trader.callProcessExecution(&execution);

  // Now create an EXPIRED execution report
  std::string id = "0"; // Generated ID in Trader::processExecution starts at 0
  std::unordered_map<std::string, boost::multiprecision::cpp_dec_float_50>
      feeDelta{};

  auto executionReport =
      ExecutionReport(id, TradeExecutionStatus::EXPIRED, feeDelta);

  // Process the report
  trader.callProcessReport(&executionReport);

  // Verify the balance is unchanged (except maybe for fees)
  EXPECT_NEAR(balance.getBalance("BTC").convert_to<double>(), 1.0, 1e-5);

  // Verify that trades are released
  for (auto &trade : execution.getOriginalTrades()) {
    EXPECT_FALSE(reservedTrades.isReserved(trade));
  }
}
