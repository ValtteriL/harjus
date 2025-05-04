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
#include <string>
class Trader {

private:
  boost::lockfree::queue<Execution *> &_executionQueue;
  boost::lockfree::queue<ExecutionReport *> &_executionReportQueue;
  IApplication &_application;
  Balance &_balance;
  ReservedTrades &_reservedTrades;
  std::unordered_map<
      std::string,
      std::tuple<Execution *,
                 std::unordered_map<std::string,
                                    boost::multiprecision::cpp_dec_float_50>>>
      _executionsMap; // Map of execution ID to execution and delta

protected:
  void processExecution(Execution *execution);
  void processReport(ExecutionReport *execReport);

public:
  Trader(boost::lockfree::queue<Execution *> &executionQueue,
         boost::lockfree::queue<ExecutionReport *> &executionReportQueue,
         IApplication &application, Balance &balance,
         ReservedTrades &reservedTrades);

  void run();
};
