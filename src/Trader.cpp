#include "Trader.h"

#include "Balance.h"
#include "Execution.h"
#include "ExecutionReport.h"
#include "IApplication.h"
#include "ReservedTrades.h"
#include "TradeExecutionStatus.h"
#include <boost/log/core.hpp>
#include <boost/log/expressions.hpp>
#include <boost/log/trivial.hpp>

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

  BOOST_LOG_TRIVIAL(trace) << "Processing execution " << *execution;

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

  // submit the first trade
  auto trade = execution->getTrades().front();

  _application.submitOrder(id, trade.getSymbol().symbol, trade.getOrderQty(),
                           trade.getOrderPrice(), trade.getPosition());
}

void Trader::processReport(ExecutionReport *execReport) {

  BOOST_LOG_TRIVIAL(debug) << "Processing execution report " << *execReport;

  auto id = execReport->getId();

  auto pair = _executionsMap.at(id);
  auto execution = pair.first;
  auto delta = pair.second;

  auto status = execReport->getStatus();

  if (status == TradeExecutionStatus::EXPIRED) {

    BOOST_LOG_TRIVIAL(info) << "Failed execution: " << *execution;

    // update balance
    _balance.updateBalance(delta);

    // free symbols
    _reservedTrades.releaseAll(execution->getOriginalTrades());

    // remove the execution from the map
    _executionsMap.erase(id);

    // free the execution
    delete execution;

    return;
  }

  // update delta
  // get fees from the execution report
  // get base, quote delta from the first trade
  auto tradeDelta = execReport->getFeeDelta();
  for (const auto &[currency, amount] : tradeDelta) {
    delta[currency] += amount;
  }

  auto oldTrade = execution->getTrades().front();
  delta[oldTrade.getUsedCurrency()] -= oldTrade.getUsedQty();
  delta[oldTrade.getRecvCurrency()] += oldTrade.getRecvQty();

  _executionsMap[id].second = delta;

  // remove the last order from the execution
  execution->getTrades().pop();

  if (execution->getTrades().empty()) {

    BOOST_LOG_TRIVIAL(info) << "Succesful execution: " << *execution;

    // remove the execution from the map
    _executionsMap.erase(id);

    // update balance
    _balance.updateBalance(delta);

    // free symbols
    _reservedTrades.releaseAll(execution->getOriginalTrades());

    // free the execution
    delete execution;

    return;
  }

  // submit the next order
  BOOST_LOG_TRIVIAL(debug) << "Submitting next order ";
  auto trade = execution->getTrades().front();

  _application.submitOrder(id, trade.getSymbol().symbol, trade.getOrderQty(),
                           trade.getOrderPrice(), trade.getPosition());
}

void Trader::run(std::stop_token stoken) {

  BOOST_LOG_TRIVIAL(debug) << "Starting Trader";

  Execution *execution = nullptr;
  ExecutionReport *execReport = nullptr;

  while (!stoken.stop_requested()) {
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

  BOOST_LOG_TRIVIAL(debug) << "Finishing executions...";

  // Finish executions that are still in the map
  while (!_executionsMap.empty()) {

    if (_executionReportQueue.pop(execReport)) {
      processReport(execReport);
      delete execReport; // Free the memory after processing
    }
  }

  BOOST_LOG_TRIVIAL(debug) << "Stopping Trader";
}