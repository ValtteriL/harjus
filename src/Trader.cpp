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
#include <chrono>
#include <random>
#include <thread>

Trader::Trader(ThreadSafeQueue<Execution> &executionQueue,
               ThreadSafeQueue<ExecutionReport> &executionReportQueue,
               IApplication &application, Balance &balance,
               ReservedTrades &reservedTrades,
               int orderSubmissionSleepMicroseconds)
    : _executionQueue(executionQueue),
      _executionReportQueue(executionReportQueue), _application(application),
      _balance(balance), _reservedTrades(reservedTrades),
      _orderSubmissionSleepMicroseconds(orderSubmissionSleepMicroseconds) {}

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

  auto executionId = generateId();
  auto delta = std::unordered_map<std::string, PreciseNumber>{
      {execution.getStartingAsset(), execution.getCapacity()}};

  if (execution.getTrades().empty()) {
    // No trades available, handle this case
    throw std::runtime_error("No trades available in the execution object");
  }

  auto trades = execution.getTrades();
  int orderCount = trades.size();

  // Submit all orders in the execution one after another
  std::jthread submitThread([this, &trades, &executionId]() {
    while (!trades.empty()) {
      auto trade = trades.front();
      trades.pop();

      auto orderId = generateId();

      // Map order ID to (StaticTrade, execution ID) for lookup in processReport
      _executionIdMap.emplace(orderId, std::make_pair(trade, executionId));

      // Submit the order
      _application.submitOrder(orderId, trade.symbol(), trade.orderQty(),
                               trade.orderPrice(), trade.position());

      // Wait configurable time between submissions
      std::this_thread::sleep_for(
          std::chrono::microseconds(_orderSubmissionSleepMicroseconds));
    }
  });

  // Store the execution and delta with execution ID
  auto pair = std::make_pair(execution, delta);
  _executionsMap.emplace(executionId, pair);

  // Initialize pending orders count
  _pendingOrdersCount[executionId] = orderCount;
}

void Trader::processReport(ExecutionReport *execReport) {

  BOOST_LOG_TRIVIAL(debug) << "Processing execution report " << *execReport;

  auto orderId = execReport->getId();
  auto status = execReport->getStatus();

  if (status == TradeExecutionStatus::REJECTED) {
    // should happen only after expired order - cleanup execution ID map
    BOOST_LOG_TRIVIAL(error) << "Rejected execution: " << *execReport;
    _executionIdMap.erase(orderId);
    return;
  }

  // Find execution ID from order ID
  auto executionIdIt = _executionIdMap.find(orderId);
  if (executionIdIt == _executionIdMap.end()) {
    BOOST_LOG_TRIVIAL(error)
        << "Order ID not found in execution map: " << orderId;
    return;
  }

  auto [oldTrade, executionId] = executionIdIt->second;
  auto pair = _executionsMap.at(executionId);
  auto execution = pair.first;
  auto delta = pair.second;

  if (status == TradeExecutionStatus::EXPIRED) {

    BOOST_LOG_TRIVIAL(info) << "Failed execution: " << execution;

    // Remove order ID mapping
    _executionIdMap.erase(orderId);

    // update balance
    _balance.updateBalance(delta);

    // free symbols
    _reservedTrades.releaseAll(execution.getOriginalTrades());

    // remove the execution from the map
    _executionsMap.erase(executionId);
    _pendingOrdersCount.erase(executionId);

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

  // If the full qty not received, additional ExecutionReports with same id will
  // be received
  auto compareQty = oldTrade.position() == Position::LONG
                        ? execReport->recvQty()
                        : execReport->usedQty();
  if (compareQty < oldTrade.orderQty()) {
    BOOST_LOG_TRIVIAL(debug) << "Partial execution, waiting for more reports";
    return;
  }

  // Decrement pending orders count for this execution
  _pendingOrdersCount[executionId]--;

  // If the full qty received, update delta with the trade
  // assuming the delta is common for all trades in the execution (cumulative)
  delta[oldTrade.usedCurrency()] -= execReport->usedQty();
  delta[oldTrade.recvCurrency()] += execReport->recvQty();

  _executionsMap[executionId].second = delta;

  // Update the execution in the map
  _executionsMap[executionId] = std::make_pair(execution, delta);

  // Remove the current order ID mapping
  _executionIdMap.erase(orderId);

  // Check if all orders in the execution are completed
  if (_pendingOrdersCount[executionId] == 0) {
    BOOST_LOG_TRIVIAL(info) << "Successful execution: " << execution;

    // Clean up all maps
    _executionsMap.erase(executionId);
    _pendingOrdersCount.erase(executionId);

    // update balance
    _balance.updateBalance(delta);

    // free symbols
    _reservedTrades.releaseAll(execution.getOriginalTrades());
  }
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