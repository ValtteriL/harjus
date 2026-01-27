#pragma once

/**
 * @brief Worker class
 * @details Trader is responsible for reacting to messages coming from Quickfix
 * application. It discovers arbitrage opportunities and makes trades while
 * keeping track of balance and reserved symbols.
 */

#include "Balance.h"
#include "Execution.h"
#include "ExecutionReport.h"
#include "IApplication.h"
#include "ReservedTrades.h"
#include <string>
#include <unordered_map>

#include "Balance.h"
#include "Execution.h"
#include "Opportunity.h"
#include "PriceUpdate.h"
#include "ReservedTrades.h"
#include "Trade.h"
#include <cstddef>
#include <string>
#include <unordered_map>

#include "PreciseNumber.h"
#include <vector>

using entry =
    std::pair<Execution, std::unordered_map<std::string, PreciseNumber>>;

class Worker
{

private:
    std::unordered_multimap<std::string, size_t> _opportunities{};
    std::vector<Opportunity> _opportunityList{};
    std::unordered_map<std::string, PreciseNumber> _relativeValues{};
    /**
     * @brief Reserves the necessary budget and trading symbols for a given
     * opportunity.
     *
     * This function allocates the required budget and locks the relevant trading
     * symbols associated with the provided Opportunity object to ensure resources
     * are available for executing the opportunity.
     *
     * @param opp Reference to the Opportunity object for which budget and symbols
     * are to be reserved.
     */
    void reserveBudgetAndSymbols(const Opportunity &opp);

protected:
    Balance *_balance;
    ReservedTrades _reservedTrades{};
    std::unordered_map<std::string, entry>
        _executionsMap{}; // Map of execution ID to execution and delta
    std::unordered_map<std::string, std::pair<StaticTrade, std::string>>
        _executionIdMap{}; // Map of order ID to (StaticTrade, execution ID)
    std::unordered_map<std::string, int>
        _pendingOrdersCount{}; // Map of execution ID to pending orders count
    std::unordered_set<std::string>
        _failedExecutions{}; // Set of failed execution IDs

public:
    /**
     * @brief Process an execution report
     * @param execReport The execution report to process
     * @details This function updates the execution status based on the report,
     * updates balances, and cleans up completed executions.
     */
    void processReport(ExecutionReport *execReport);

    /**
     * Process a price update
     * @param update The price update to process
     * @param application The application instance to use for submitting orders
     * @details This function updates the symbol prices and checks opportunities
     * for profitability. It finds 2 most profitable non-overlapping
     * opportunities, reserves symbols and budget for them, and queues them for
     * execution.
     */
    void processPriceUpdate(const PriceUpdate &update, IApplication &application);

    /**
     * @brief Constructor for the Engine class.
     * @param symbols A reference to a map of symbols.
     * @param tradingPaths A reference to a vector of trading paths.
     * @param balance A reference to a Balance object.
     * @param reservedTrades A reference to a ReservedTrades object.
     * @param priceUpdateQueue A reference to a lock-free queue for price updates.
     * @param executionQueue A reference to a thread safe queue for executions.
     * @param relativeValues A map of relative values for symbols.
     */
    Worker(std::vector<std::vector<Trade>> &tradingPaths,
           std::unordered_map<std::string, PreciseNumber> &relativeValues,
           Balance &balance, const PreciseNumber &commission);
};
