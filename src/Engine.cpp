#include "Engine.h"
#include "Execution.h"
#include <string>

Engine::Engine(
    std::unordered_map<std::string, Symbol> &symbols,
    std::vector<std::vector<Trade> *> &tradingPaths, Balance &balance,
    ReservedTrades &reservedTrades,
    boost::lockfree::queue<PriceUpdate *> &priceUpdateQueue,
    boost::lockfree::queue<Execution> &executionQueue,
    std::unordered_map<std::string, boost::multiprecision::cpp_dec_float_50>
        relativeValues,
    boost::multiprecision::cpp_dec_float_50 commission)
    : _symbols(symbols), _relativeValues(relativeValues),
      _priceUpdateQueue(priceUpdateQueue), _executionQueue(executionQueue),
      _reservedTrades(reservedTrades), _balance(balance) {

  // Initialize _executions with the trading paths
  for (auto &path : tradingPaths) {

    // create an execution
    std::string startingAsset = path->at(0).getUsedCurrency();
    Execution *execution =
        new Execution(*path, _relativeValues[startingAsset], commission);

    // add execution to _executions with every trade symbol as the key
    for (auto &trade : *path) {
      _executions.insert({trade.getSymbol().symbol, *execution});
    }
  }
};

bool Engine::containsOnlyFreeSymbols(Execution &execution) {
  for (auto &trade : execution.getTrades()) {
    if (_reservedTrades.isReserved(trade.getSymbol().symbol)) {
      return false;
    }
  }
  return true;
}

void Engine::run() {

  while (true) {
    PriceUpdate *update = nullptr;
    if (_priceUpdateQueue.pop(update)) {

      // update symbol price
      _symbols[update->symbol].askPrice = update->askPrice;
      _symbols[update->symbol].bidPrice = update->bidPrice;
      _symbols[update->symbol].askQty = update->askQty;
      _symbols[update->symbol].bidQty = update->bidQty;

      // update all affected executions
      auto affectedExecutions = _executions.equal_range(
          update->symbol); // get all affected executions

      for (auto it = affectedExecutions.first; it != affectedExecutions.second;
           ++it) {

        auto startingAssetBudget =
            _balance.getBalance(it->second.getStartingAsset());

        // update the execution with the new price
        it->second.update(startingAssetBudget);
      }

      // TODO: take 2 non-overlapping executions with the largest profit
      Execution *mostProfitableExecution = nullptr;
      for (auto it = affectedExecutions.first; it != affectedExecutions.second;
           ++it) {

        auto trade = it->second;

        if ((!mostProfitableExecution ||
             (trade.getTotalProfit() > 0 &&
              trade.getTotalProfit() >
                  mostProfitableExecution->getTotalProfit())) &&
            containsOnlyFreeSymbols(trade)) {
          mostProfitableExecution = &trade;
        }
      }

      // lock resources for the best execution
      if (mostProfitableExecution) {
        for (auto &trade : mostProfitableExecution->getTrades()) {
          _reservedTrades.reserve(trade.getSymbol().symbol);
        }
      }

      // reduce balance

      // update executions that use the same starting asset

      // find the second most profitable now

      // TODO: queue executions to the execution queue

      // clean up the update
      delete update;
    }
  }
}