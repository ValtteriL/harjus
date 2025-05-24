#include "Trader.h"

#include "Balance.h"
#include "Execution.h"
#include "ExecutionReport.h"
#include "IApplication.h"
#include "Position.h"
#include "ReservedTrades.h"
#include "ThreadSafeQueue.h"
#include "TradeExecutionStatus.h"
#include <algorithm>
#include <boost/log/core.hpp>
#include <boost/log/expressions.hpp>
#include <boost/log/trivial.hpp>
#include <random>

Trader::Trader(ThreadSafeQueue<Execution> &executionQueue,
               ThreadSafeQueue<ExecutionReport> &executionReportQueue,
               IApplication &application, Balance &balance,
               ReservedTrades &reservedTrades)
    : _executionQueue(executionQueue),
      _executionReportQueue(executionReportQueue), _application(application),
      _balance(balance), _reservedTrades(reservedTrades) {}

/** Generate ID for execution */
std::string generateId() {
  static const char charset[] = "abcdefghijklmnopqrstuvwxyz0123456789";
  static thread_local std::mt19937 rng(std::random_device{}());
  static std::uniform_int_distribution<> dist(0, sizeof(charset) - 2);
  std::string id(8, '\0');
  std::generate_n(id.begin(), 8, [&]() { return charset[dist(rng)]; });
  return id;
}

void Trader::processExecution(Execution execution) {

  BOOST_LOG_TRIVIAL(debug) << "Processing execution " << execution;

  auto id = generateId();
  auto delta = std::unordered_map<std::string, PreciseNumber>{
      {execution.getStartingAsset(), execution.getCapacity()}};

  auto pair = std::make_pair(execution, delta);

  // Store the execution and delta in the map
  _executionsMap.emplace(id, pair);

  // pop the first trade from the execution
  // and submit the order
  if (execution.getTrades().empty()) {
    // No trades available, handle this case
    throw std::runtime_error("No trades available in the execution object");
  }

  // submit the first trade
  auto trade = execution.getTrades().front();

  _application.submitOrder(id, trade.symbol(), trade.orderQty(),
                           trade.orderPrice(), trade.position());
}

void Trader::processReport(ExecutionReport *execReport) {

  BOOST_LOG_TRIVIAL(debug) << "Processing execution report " << *execReport;

  auto id = execReport->getId();

  auto pair = _executionsMap.at(id);
  auto execution = pair.first;
  auto delta = pair.second;

  auto status = execReport->getStatus();

  if (status == TradeExecutionStatus::EXPIRED) {

    BOOST_LOG_TRIVIAL(info) << "Failed execution: " << execution;

    // update balance
    _balance.updateBalance(delta);

    // free symbols
    _reservedTrades.releaseAll(execution.getOriginalTrades());

    // remove the execution from the map
    _executionsMap.erase(id);

    return;
  }

  // update delta with fees
  // get fees from the execution report
  // get base, quote delta from the first trade
  // assuming the fees are unique for all partial executions
  auto tradeDelta = execReport->getFeeDelta();
  for (const auto &[currency, amount] : tradeDelta) {
    delta[currency] += amount;
  }

  auto oldTrade = execution.getTrades().front();

  // If the full qty not received, additional ExecutionReports with same id will
  // be received
  auto compareQty = oldTrade.position() == Position::LONG
                        ? execReport->recvQty()
                        : execReport->usedQty();
  if (compareQty < oldTrade.orderQty()) {
    BOOST_LOG_TRIVIAL(debug) << "Partial execution, waiting for more reports";
    return;
  }

  // If the full qty received, update delta with the trade
  // assuming the delta is common for all trades in the execution (cumulative)
  delta[oldTrade.usedCurrency()] -= execReport->usedQty();
  delta[oldTrade.recvCurrency()] += execReport->recvQty();

  _executionsMap[id].second = delta;

  // remove the last order from the execution
  execution.getTrades().pop();

  if (execution.getTrades().empty()) {

    BOOST_LOG_TRIVIAL(info) << "Succesful execution: " << execution;

    // remove the execution from the map
    _executionsMap.erase(id);

    // update balance
    _balance.updateBalance(delta);

    // free symbols
    _reservedTrades.releaseAll(execution.getOriginalTrades());

    return;
  }

  // submit the next order with a new ID
  BOOST_LOG_TRIVIAL(debug) << "Submitting next order ";
  auto trade = execution.getTrades().front();

  // Generate a new ID for the next order
  auto newId = generateId();
  // Move the execution and delta to the new ID in the map
  _executionsMap.emplace(newId, std::make_pair(execution, delta));
  _executionsMap.erase(id);

  _application.submitOrder(newId, trade.symbol(), trade.orderQty(),
                           trade.orderPrice(), trade.position());
}

void Trader::run(std::stop_token stoken) {

  BOOST_LOG_TRIVIAL(debug) << "Starting Trader";

  // Wait for the semaphore to be released
  // or stop requested
  while (!stoken.stop_requested()) {

    if (_executionQueue.getSemaphore().try_acquire_for(
            std::chrono::milliseconds(100))) {

      // Process execution
      if (Execution execution; _executionQueue.try_pop(execution)) {
        processExecution(execution);
      }

      // Process execution report
      if (ExecutionReport executionReport;
          _executionReportQueue.try_pop(executionReport)) {
        processReport(&executionReport);
      }
    }
  }

  BOOST_LOG_TRIVIAL(debug) << "Finishing executions...";

  // Finish executions that are still in the map
  while (!_executionsMap.empty()) {

    _executionReportQueue.getSemaphore().acquire();

    if (ExecutionReport executionReport;
        _executionReportQueue.try_pop(executionReport)) {
      processReport(&executionReport);
    }
  }

  BOOST_LOG_TRIVIAL(debug) << "Stopping Trader";
}