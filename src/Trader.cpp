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

  auto pair = std::make_pair(execution, delta);

  // Store the execution and delta in the map
  _executionsMap.emplace(id, pair);

  // pop the first trade from the execution
  // and submit the order
  if (execution->getTrades().empty()) {
    // No trades available, handle this case
    throw std::runtime_error("No trades available in the execution object");
  }

  // pop the first trade
  auto trade = execution->getTrades().front();
  execution->getTrades().pop();

  _application.submitOrder(id, trade.getSymbol().symbol, trade.getOrderQty(),
                           trade.getOrderPrice(), trade.getPosition());
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