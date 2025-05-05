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
#include <boost/lockfree/queue.hpp>
#include <stop_token>
#include <string>

using entry = std::pair<
    Execution *,
    std::unordered_map<std::string, boost::multiprecision::cpp_dec_float_50>>;

class Trader {

private:
  boost::lockfree::queue<Execution *> &_executionQueue;
  boost::lockfree::queue<ExecutionReport *> &_executionReportQueue;
  IApplication &_application;
  Balance &_balance;
  ReservedTrades &_reservedTrades;
  std::unordered_map<std::string,
                     entry>
      _executionsMap; // Map of execution ID to execution and delta

protected:
  void processExecution(Execution *execution);
  void processReport(ExecutionReport *execReport);

public:
  Trader(boost::lockfree::queue<Execution *> &executionQueue,
         boost::lockfree::queue<ExecutionReport *> &executionReportQueue,
         IApplication &application, Balance &balance,
         ReservedTrades &reservedTrades);

  /**
   * @brief Run the trader
   * @param stoken The stop token to stop the thread
   * @details This function runs the trader in a loop, processing executions and
   * execution reports.
   */
  void run(std::stop_token stoken);
};
