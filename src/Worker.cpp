#include "Worker.h"

#include "Balance.h"
#include "Execution.h"
#include "ExecutionReport.h"
#include "IApplication.h"
#include "Position.h"
#include "ReservedTrades.h"
#include "TradeExecutionStatus.h"
#include <algorithm>
#include <boost/log/core.hpp>
#include <boost/log/expressions.hpp>
#include <boost/log/trivial.hpp>
#include <random>
#include <stdexcept>

Worker::Worker(
    std::vector<std::vector<Trade>> &tradingPaths,
    boost::lockfree::spsc_queue<PriceUpdate> &priceUpdateQueue,
    boost::lockfree::spsc_queue<ExecutionReport> &executionReportQueue,
    IApplication &application,
    std::unordered_map<std::string, PreciseNumber> &relativeValues,
    Balance &balance, const PreciseNumber &commission)
    : _priceUpdateQueue(&priceUpdateQueue),
      _executionReportQueue(&executionReportQueue), _application(&application),
      _relativeValues(relativeValues), _balance(&balance) {

  // Initialize _opportunities with the trading paths
  for (auto &path : tradingPaths) {

    // create an opportunity
    std::string startingAsset = path.front().usedCurrency();
    _opportunityList.emplace_back(path, _relativeValues[startingAsset],
                                  commission);

    auto index = _opportunityList.size() - 1;

    // add opportunity to _opportunities with every trade symbol as the key
    for (auto &trade : path) {
      _opportunities.insert({trade.symbol()->symbol, index});
    }
  }
}

void Worker::reserveBudgetAndSymbols(const Opportunity &opp) {
  _reservedTrades.reserveAll(opp.getTrades());
  _balance->updateBalance(opp.getStartingAsset(),
                          opp.getCapacity() * PreciseNumber{"-1"});
}

/** Generate ID for execution */
auto generateId() -> std::string {
  static constexpr std::array<char, 36> charset = {
      'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l',
      'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x',
      'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'};
  static constexpr std::size_t ID_LENGTH = 8;
  static thread_local std::mt19937 rng(std::random_device{}());
  static std::uniform_int_distribution<> dist(0, charset.size() - 1);
  std::string id(ID_LENGTH, '\0');
  std::generate_n(id.begin(), ID_LENGTH,
                  [&]() { return charset.at(dist(rng)); });
  return id;
}

void Worker::processPriceUpdate(const PriceUpdate &update) {
  // Update symbol price
  update.symbol->askPrice = update.askPrice;
  update.symbol->bidPrice = update.bidPrice;
  update.symbol->askQty = update.askQty;
  update.symbol->bidQty = update.bidQty;

  // get balances
  const auto balanceMap = _balance->getBalances();

  // get reserved trades
  auto reservedSymbols = _reservedTrades.getReservedTrades();

  Opportunity *best = nullptr;

  // Update all affected opportunities
  auto affected = _opportunities.equal_range(update.symbol->symbol);
  for (auto &it = affected.first; it != affected.second; ++it) {

    auto &opp = _opportunityList.at(it->second);

    // Check if starting asset is available and has positive balance
    auto search = balanceMap.find(opp.getStartingAsset());
    if (search == balanceMap.end() || PreciseNumber{"0"} >= search->second) {
      continue;
    }

    // Update the opportunity with the new price and balance
    opp.update(search->second);

    auto trades = opp.getTrades();

    if (PreciseNumber{"0"} >= opp.getTotalProfit() ||
        std::any_of(trades.begin(), trades.end(),
                    [&reservedSymbols](const StaticTrade &trade) {
                      return reservedSymbols.contains(trade.symbol());
                    }))
      continue;

    // If the opportunity is profitable and does not contain reserved symbols,
    // check if it's the best one
    if (!best || opp.getTotalProfit() > best->getTotalProfit()) {
      best = &opp;
    }
  }

  if (!best)
    return;

  reserveBudgetAndSymbols(*best);

  // Freeze and queue the best opportunity for execution
  Execution execution{*best};

  BOOST_LOG_TRIVIAL(debug) << "Processing execution " << execution;

  auto executionId = generateId();
  auto delta = std::unordered_map<std::string, PreciseNumber>{
      {execution.getStartingAsset(), execution.getCapacity()}};
  auto trades = execution.getTrades();

  // Submit all orders in the execution one after another
  while (!trades.empty()) {
    auto trade = trades.front();
    trades.pop();

    auto orderId = generateId();

    // Map order ID to (StaticTrade, execution ID) for lookup in processReport
    _executionIdMap.emplace(orderId, std::make_pair(trade, executionId));

    // Submit the order
    _application->submitOrder(orderId, trade.symbol(), trade.orderQty(),
                              trade.orderPrice(), trade.position());
  }

  // Store the execution and delta with execution ID
  auto pair = std::make_pair(execution, delta);
  _executionsMap.emplace(executionId, pair);

  // Initialize pending orders count
  _pendingOrdersCount[executionId] = execution.getTrades().size();
}

void Worker::processReport(ExecutionReport *execReport) {

  BOOST_LOG_TRIVIAL(debug) << "Processing execution report " << *execReport;

  auto orderId = execReport->getId();
  auto status = execReport->getStatus();

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

  switch (status) {
  case TradeExecutionStatus::REJECTED: {
    // should happen only after expired order - cleanup execution ID map
    BOOST_LOG_TRIVIAL(debug) << "Trade rejected: " << *execReport;

    // Mark execution as failed
    _failedExecutions.insert(executionId);

    break;
  }
  case TradeExecutionStatus::EXPIRED: {
    BOOST_LOG_TRIVIAL(debug) << "Trade expired: " << execution;

    // Mark execution as failed
    _failedExecutions.insert(executionId);

    break;
  }
  case TradeExecutionStatus::FILLED: {

    BOOST_LOG_TRIVIAL(debug) << "Trade filled: " << *execReport;

    // update delta with fees
    // get fees from the execution report
    // get base, quote delta from the first trade
    // assuming the fees are unique for all partial executions
    auto tradeDelta = execReport->getFeeDelta();
    for (const auto &[currency, amount] : tradeDelta) {
      delta[currency] += amount;
    }

    // If the full qty not received, additional ExecutionReports with same id
    // will be received
    auto compareQty = oldTrade.position() == Position::LONG
                          ? execReport->recvQty()
                          : execReport->usedQty();
    if (compareQty < oldTrade.orderQty()) {
      BOOST_LOG_TRIVIAL(debug) << "Partial execution, waiting for more reports";
      return;
    }

    // If the full qty received, update delta with the trade
    // assuming the delta is common for all trades in the execution
    // (cumulative)
    delta[oldTrade.usedCurrency()] -= execReport->usedQty();
    delta[oldTrade.recvCurrency()] += execReport->recvQty();

    _executionsMap[executionId].second = delta;

    // Update the execution in the map
    _executionsMap[executionId] = std::make_pair(execution, delta);

    break;
  }
  default:
    BOOST_LOG_TRIVIAL(info)
        << "Unknown ExecutionReport status: " << *execReport;
    throw std::runtime_error("Unknown ExecutionReport status");
  }

  // Remove the current order ID mapping
  _executionIdMap.erase(orderId);

  // Decrement pending orders count for this execution
  _pendingOrdersCount[executionId]--;

  // Check if all orders in the execution are completed
  if (_pendingOrdersCount[executionId] == 0) {

    if (!_failedExecutions.contains(executionId)) {
      BOOST_LOG_TRIVIAL(info) << "Successful execution: " << execution;
    } else {
      BOOST_LOG_TRIVIAL(info) << "Failed execution: " << execution;
    }

    // Clean up all maps and sets
    _executionsMap.erase(executionId);
    _pendingOrdersCount.erase(executionId);
    _failedExecutions.erase(executionId);

    // update balance
    _balance->updateBalance(delta);

    // free symbols
    _reservedTrades.releaseAll(execution.getOriginalTrades());
  }
}

void Worker::run(const std::stop_token &stoken) {

  BOOST_LOG_TRIVIAL(debug) << "Starting Trader";

  // Wait for the semaphore to be released
  // or stop requested
  while (!stoken.stop_requested()) {

    // Process price update
    if (PriceUpdate update; _priceUpdateQueue->pop(update)) {
      processPriceUpdate(update);
    }

    // Process execution report
    if (ExecutionReport executionReport;
        _executionReportQueue->pop(executionReport)) {
      processReport(&executionReport);
    }
  }

  BOOST_LOG_TRIVIAL(debug) << "Finishing executions...";

  // Finish executions that are still in the map
  while (!_executionsMap.empty()) {

    if (ExecutionReport executionReport;
        _executionReportQueue->pop(executionReport)) {
      processReport(&executionReport);
    }
  }

  BOOST_LOG_TRIVIAL(debug) << "Stopping Trader";
}