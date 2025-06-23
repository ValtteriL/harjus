#pragma once

/**
 * @brief Trader class
 * @details Trader is responsible for fulfilling executions by placing orders
 * and releasing resources reserved for executions
 */

#include "Balance.h"
#include "Execution.h"
#include "ExecutionReport.h"
#include "IApplication.h"
#include "ReservedTrades.h"
#include <stop_token>
#include <string>
#include <unordered_map>

using entry =
    std::pair<Execution, std::unordered_map<std::string, PreciseNumber>>;

class Trader {

private:
  boost::lockfree::spsc_queue<Execution> *_executionQueue;
  boost::lockfree::spsc_queue<ExecutionReport> *_executionReportQueue;
  IApplication *_application;
  Balance *_balance;
  ReservedTrades *_reservedTrades;

protected:
  void processExecution(const Execution &execution);
  void processReport(ExecutionReport *execReport);
  std::unordered_map<std::string, entry>
      _executionsMap{}; // Map of execution ID to execution and delta
  std::unordered_map<std::string, std::pair<StaticTrade, std::string>>
      _executionIdMap{}; // Map of order ID to (StaticTrade, execution ID)
  std::unordered_map<std::string, int>
      _pendingOrdersCount{}; // Map of execution ID to pending orders count
  std::unordered_set<std::string>
      _failedExecutions{}; // Set of failed execution IDs

public:
  Trader(boost::lockfree::spsc_queue<Execution> &_executionQueue,
         boost::lockfree::spsc_queue<ExecutionReport> &executionReportQueue,
         IApplication &application, Balance &balance,
         ReservedTrades &reservedTrades);

  /**
   * @brief Run the trader
   * @param stoken The stop token to stop the thread
   * @details This function runs the trader in a loop, processing executions and
   * execution reports.
   */
  void run(const std::stop_token &stoken);
};
