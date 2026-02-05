/*
 * WorkerTest.cpp
 * Testing the Worker class.
 */

#include "Worker.h"
#include "Application_test.h"
#include "Balance.h"
#include "Execution.h"
#include "ExecutionReport.h"
#include "IApplication.h"
#include "Position.h"
#include "PreciseNumber.h"
#include "PriceUpdate.h"
#include "TradeExecutionStatus.h"
#include <boost/lockfree/spsc_queue.hpp>
#include <gmock/gmock.h>
#include <gtest/gtest.h>
#include <string>
#include <unordered_map>
#include <vector>

#include <gmock/gmock.h>
#include <gtest/gtest.h>

using ::testing::_;
using ::testing::Return;

class TestableWorker : public Worker
{
public:
    TestableWorker(
        std::vector<std::vector<Trade>> &tradingPaths,
        boost::lockfree::spsc_queue<PriceUpdate> &priceUpdateQueue,
        boost::lockfree::spsc_queue<ExecutionReport> &executionReportQueue,
        IApplication &application,
        Balance &balance,
        std::unordered_map<std::string, PreciseNumber> relativeValues,
        const PreciseNumber &commission)
        : Worker(tradingPaths, priceUpdateQueue, executionReportQueue, application, relativeValues, balance, commission) {}

    // Expose private methods for testing
    void callProcessPriceUpdate(const PriceUpdate &update)
    {
        // Call the original processPriceUpdate method
        processPriceUpdate(update);
    }

    void callProcessReport(ExecutionReport *execReport)
    {
        processReport(execReport);
    }

    // Access to internal maps for advanced testing if needed
    [[nodiscard]] auto getExecutionsMap() const -> const auto &
    {
        return _executionsMap;
    }
    [[nodiscard]] auto getExecutionIdMap() const -> const auto &
    {
        return _executionIdMap;
    }
    [[nodiscard]] auto getPendingOrdersCount() const -> const auto &
    {
        return _pendingOrdersCount;
    }
    [[nodiscard]] auto getFailedExecutions() const -> const auto &
    {
        return _failedExecutions;
    }
    [[nodiscard]] auto getReservedTrades() const -> const auto &
    {
        return _reservedTrades;
    }
    [[nodiscard]] auto getBalance() const -> const Balance & { return *_balance; }
};

/**
 * Test fixture for Engine.
 */

class WorkerTest : public testing::Test
{

    constexpr static auto precision = 8;
    const PreciseNumber dummySmall{"0.0001"};
    static constexpr std::size_t QUEUE_SIZE = 100;

protected:
    const PreciseNumber zero{"0.0"};
    MockApplication mockApplication;
    PreciseNumber startingAssetBudget{"1.0"};
    Balance balance;
    std::unordered_map<std::string, Symbol> symbolsMap{};
    std::unordered_map<std::string, PreciseNumber> relativeValues{
        {"BTC", PreciseNumber{"1.0"}},
        {"ETH", PreciseNumber{"1.0"}},
        {"USDT", PreciseNumber{"1.0"}}};
    PreciseNumber commission{"0.001"};
    boost::lockfree::spsc_queue<PriceUpdate> priceUpdateQueue{QUEUE_SIZE};
    boost::lockfree::spsc_queue<ExecutionReport> executionReportQueue{QUEUE_SIZE};

    Symbol ethBtcSymbol{"ETHBTC", "ETH", "BTC", dummySmall,
                        dummySmall, dummySmall, precision, precision,
                        zero, zero, zero, zero};
    Symbol ethUsdtSymbol{"ETHUSDT", "ETH", "USDT", dummySmall,
                         dummySmall, dummySmall, precision, precision,
                         zero, zero, zero, zero};
    Symbol usdtBtcSymbol{"USDTBTC", "USDT", "BTC", dummySmall,
                         dummySmall, dummySmall, precision, precision,
                         zero, zero, zero, zero};

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
        : balance({{"BTC", startingAssetBudget}}), tradingPaths({trades}),
          worker(tradingPaths, priceUpdateQueue, executionReportQueue, mockApplication, balance, relativeValues, commission)
    {
    }

    // Helper method to create a simple opportunity
    auto createSimpleOpportunity() -> std::vector<PriceUpdate>
    {

        std::vector<PriceUpdate> updates{};
        updates.push_back(PriceUpdate{&symbols.at("ETHBTC"), zero,
                                      PreciseNumber{"1"}, zero,
                                      PreciseNumber{"100"}}); // BTC -> ETH 1:1
        updates.push_back(PriceUpdate{&symbols.at("ETHUSDT"), PreciseNumber{"1"},
                                      zero, PreciseNumber{"1"},
                                      zero}); // ETH -> USDT 1:1
        updates.push_back(PriceUpdate{&symbols.at("USDTBTC"), PreciseNumber{"10.0"},
                                      zero, PreciseNumber{"1.0"},
                                      zero}); // USDT -> BTC 1:10

        return updates;
    }

    void verifyExecutionProperties(const Execution &execution,
                                   const PreciseNumber &startingAssetBudget,
                                   const PreciseNumber &profit,
                                   const PreciseNumber &initialBalance,
                                   const std::string &asset)
    {
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

TEST_F(WorkerTest, detectsArbitrageOpportunity)
{

    auto updates = createSimpleOpportunity();

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

    // Process the price updates
    for (auto &update : updates)
    {
        worker.callProcessPriceUpdate(update);
    }

    // verify that balance is reserved
    EXPECT_EQ(balance.getBalances().at("BTC"), zero);

    // Verify that trades are reserved
    EXPECT_EQ(worker.getReservedTrades().getReservedTrades().size(), 3);
}

TEST_F(WorkerTest, processesFilledExecutionReportCompleted)
{
    // Create an opportunity and execution
    auto updates = createSimpleOpportunity();

    // Expect calls to submitOrder for all trades in the execution
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

    for (const auto &update : updates)
    {
        worker.callProcessPriceUpdate(update);
    }

    std::unordered_map<std::string, PreciseNumber> feeDelta{
        {"BTC", PreciseNumber{"-0.1"}} // Example fee
    };

    // get all order IDs from the execution ID map as vector
    // need to do this because the map is modified in the loop
    std::vector<std::string> orderIds{};
    for (const auto &trade : worker.getExecutionIdMap())
    {
        orderIds.push_back(trade.first);
    }

    for (const auto &orderId : orderIds)
    {

        // Insert a partial execution report (not full fill)
        // using negative values as the test opportunity has zero recvQty & usedQty
        ExecutionReport partialReport{orderId, TradeExecutionStatus::FILLED,
                                      PreciseNumber{"-1"}, PreciseNumber{"-1"},
                                      feeDelta};

        worker.callProcessReport(&partialReport);

        // Create a filled execution report for each trade
        ExecutionReport executionReport{orderId, TradeExecutionStatus::FILLED,
                                        PreciseNumber{"1"}, PreciseNumber{"2"},
                                        feeDelta};

        // Process the filled execution report
        worker.callProcessReport(&executionReport);
    }

    // Verify the balance is updated correctly
    // Initial BTC balance: 1.0
    // Fees: -0.3 BTC
    // 1st trade, spending: 1 BTC
    // 3rd trade, receiving: 2 BTC
    // Final BTC balance: 1 - 1 - 0.3 + 2 = 1.7
    //
    // Initial ETH balance: 0
    // 1st trade, receiving: 2 ETH
    // 2nd trade, spending: 1 ETH
    // Final ETH balance: 0 + 2 - 1 = 1
    //
    // Initial USDT balance: 0
    // 2nd trade, receiving: 2 USDT
    // 3rd trade, spending: 1 USDT
    // Final USDT balance: 0 + 2 - 1 = 1
    EXPECT_EQ(balance.getBalances().at("BTC"), PreciseNumber{"1.7"});
    EXPECT_EQ(balance.getBalances().at("USDT"), PreciseNumber{"1"});
    EXPECT_EQ(balance.getBalances().at("ETH"), PreciseNumber{"1"});
}

TEST_F(WorkerTest, processesExpiredExecutionReport)
{
    // Create an opportunity and execution
    auto updates = createSimpleOpportunity();

    // Expect calls to submitOrder for all trades in the execution
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

    for (const auto &update : updates)
    {
        worker.callProcessPriceUpdate(update);
    }

    // expire all orders in the execution
    // This simulates the scenario where the orders are not filled and expire
    // without any trades being executed.

    // must collect all order IDs from the execution ID map
    // because the map is modified in the loop
    // and we cannot iterate over it while modifying
    std::vector<std::string> orderIds{};
    for (const auto &trade : worker.getExecutionIdMap())
    {
        orderIds.push_back(trade.first);
    }

    for (const auto &orderId : orderIds)
    {
        ExecutionReport executionReport{
            orderId, TradeExecutionStatus::EXPIRED, zero, zero, {}};

        worker.callProcessReport(&executionReport);
    }

    // Verify the balance is unchanged
    EXPECT_EQ(balance.getBalances().at("BTC"), PreciseNumber{"1.0"});

    // Verify that reserved trades are cleared
    EXPECT_TRUE(worker.getReservedTrades().getReservedTrades().empty());
}
