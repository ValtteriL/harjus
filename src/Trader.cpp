#include "Trader.h"

#include "Application.h"
#include "Balance.h"
#include "Execution.h"
#include "ExecutionReport.h"
#include "ReservedTrades.h"

Trader::Trader(boost::lockfree::queue<Execution *> &executionQueue,
               boost::lockfree::queue<ExecutionReport *> &executionReportQueue,
               Application &application, Balance &balance,
               ReservedTrades &reservedTrades)
    : _executionQueue(executionQueue),
      _executionReportQueue(executionReportQueue), _application(application),
      _balance(balance), _reservedTrades(reservedTrades) {}

void Trader::processExecution(Execution *execution) {}

void Trader::processReport(ExecutionReport *execReport) {}

void Trader::run() {

  Execution *execution = nullptr;
  ExecutionReport *execReport = nullptr;

  while (true) {
    // Process execution
    if (_executionQueue.pop(execution)) {
      processExecution(execution);
      delete execution; // Free the memory after processing
    }

    // Process execution report
    if (_executionReportQueue.pop(execReport)) {
      processReport(execReport);
      delete execReport; // Free the memory after processing
    }
  }
}