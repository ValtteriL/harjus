#include "Trader.h"

#include "Balance.h"
#include "Execution.h"
#include "ExecutionReport.h"
#include "IApplication.h"
#include "ReservedTrades.h"

Trader::Trader(boost::lockfree::queue<Execution *> &executionQueue,
               boost::lockfree::queue<ExecutionReport *> &executionReportQueue,
               IApplication &application, Balance &balance,
               ReservedTrades &reservedTrades)
    : _executionQueue(executionQueue),
      _executionReportQueue(executionReportQueue), _application(application),
      _balance(balance), _reservedTrades(reservedTrades) {}

/** Generate ID for execution */
std::string generateId() {
  static int id = 0;
  return std::to_string(id++);
}

void Trader::processExecution(Execution *execution) {
  auto id = generateId();
  auto delta =
      std::unordered_map<std::string, boost::multiprecision::cpp_dec_float_50>{
          {execution->getStartingAsset(), execution->getCapacity()}};

  // TODO - may need to use stack or queue for the trades in execution to make
  // popping from the front possible

  // _executionsMap.emplace(id, {execution, delta});

  // // pop the first trade from the execution
  // // and submit the order
  // if (execution->getTrades().empty()) {
  //   // No trades available, handle this case
  //   return;
  // }

  // auto trade = execution->getTrades().front();

  // _application.submitOrder(id, trade.getSymbol().symbol, trade.getOrderQty(),
  //                          trade.getOrderPrice(), trade.getPosition());
}

void Trader::processReport(ExecutionReport *execReport) {}

void Trader::run() {

  Execution *execution = nullptr;
  ExecutionReport *execReport = nullptr;

  while (true) {
    // Process execution
    if (_executionQueue.pop(execution)) {
      processExecution(execution);
    }

    // Process execution report
    if (_executionReportQueue.pop(execReport)) {
      processReport(execReport);
      delete execReport; // Free the memory after processing
    }
  }
}