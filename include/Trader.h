#pragma once

/**
 * @brief Trader class
 * @details Trader is responsible for fulfilling executions by placing orders
 * and releasing resources reserved for executions
 */

#include "Application.h"
#include "Balance.h"
#include "Execution.h"
#include "ExecutionReport.h"
#include "ReservedTrades.h"
#include <boost/lockfree/queue.hpp>
class Trader {

private:
  boost::lockfree::queue<Execution *> &_executionQueue;
  boost::lockfree::queue<ExecutionReport *> &_executionReportQueue;
  Application &_application;
  Balance &_balance;
  ReservedTrades &_reservedTrades;

protected:
  void processExecution(Execution *execution);
  void processReport(ExecutionReport *execReport);

public:
  Trader(boost::lockfree::queue<Execution *> &executionQueue,
         boost::lockfree::queue<ExecutionReport *> &executionReportQueue,
         Application &application, Balance &balance,
         ReservedTrades &reservedTrades);

  void run();
};
