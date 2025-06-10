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
#include "ThreadSafeQueue.h"
#include <stop_token>
#include <string>

using entry =
    std::pair<Execution, std::unordered_map<std::string, PreciseNumber>>;

class Trader {

private:
  ThreadSafeQueue<Execution> &_executionQueue;
  ThreadSafeQueue<ExecutionReport> &_executionReportQueue;
  IApplication &_application;
  Balance &_balance;
  ReservedTrades &_reservedTrades;
  const int _orderSubmissionSleepMicroseconds;

protected:
  void processExecution(Execution execution);
  void processReport(ExecutionReport *execReport);
  std::unordered_map<std::string, entry>
      _executionsMap; // Map of execution ID to execution and delta
  std::unordered_map<std::string, std::pair<StaticTrade, std::string>>
      _executionIdMap; // Map of order ID to (StaticTrade, execution ID)
  std::unordered_map<std::string, int>
      _pendingOrdersCount; // Map of execution ID to pending orders count

public:
  Trader(ThreadSafeQueue<Execution> &_executionQueue,
         ThreadSafeQueue<ExecutionReport> &executionReportQueue,
         IApplication &application, Balance &balance,
         ReservedTrades &reservedTrades, int orderSubmissionSleepMicroseconds);

  /**
   * @brief Run the trader
   * @param stoken The stop token to stop the thread
   * @details This function runs the trader in a loop, processing executions and
   * execution reports.
   */
  void run(std::stop_token stoken);
};
