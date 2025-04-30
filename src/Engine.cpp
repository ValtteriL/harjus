#include "Engine.h"
#include "Execution.h"
#include <iterator>
#include <string>
#include <vector>

Engine::Engine(
    std::unordered_map<std::string, Symbol> &symbols,
    std::vector<std::vector<Trade> *> &tradingPaths, Balance &balance,
    ReservedTrades &reservedTrades,
    boost::lockfree::queue<PriceUpdate *> &priceUpdateQueue,
    boost::lockfree::queue<Execution *> &executionQueue,
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
    if (_reservedTrades.isReserved(trade)) {
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

      // clean up the update
      delete update;

      std::vector<Execution *> opportunitiesToQueue;

      // update all affected executions
      auto affectedExecutions = _executions.equal_range(
          update->symbol); // get all affected executions

      for (auto it = affectedExecutions.first; it != affectedExecutions.second;
           ++it) {

        auto trade = it->second;

        auto startingAssetBudget =
            _balance.getBalance(trade.getStartingAsset());

        // update the execution with the new price
        trade.update(startingAssetBudget);
      }

      // find the most profitable execution
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

      // if no most profitable execution is found, there isn't second most
      // profitable execution either
      if (!mostProfitableExecution) {
        continue;
      }

      opportunitiesToQueue.push_back(mostProfitableExecution);

      // lock symbols, balance for the best execution
      for (auto &trade : mostProfitableExecution->getTrades()) {
        _reservedTrades.reserve(trade);
      }
      _balance.updateBalance(mostProfitableExecution->getStartingAsset(),
                             mostProfitableExecution->getCapacity() * -1);

      // update executions that use the same starting asset
      auto newBalance =
          _balance.getBalance(mostProfitableExecution->getStartingAsset());
      for (auto it = affectedExecutions.first; it != affectedExecutions.second;
           ++it) {

        auto trade = it->second;

        if (trade.getStartingAsset() ==
            mostProfitableExecution->getStartingAsset()) {
          trade.update(newBalance);
        }
      }

      // find the second most profitable
      Execution *secondMostProfitable = nullptr;
      for (auto it = affectedExecutions.first; it != affectedExecutions.second;
           ++it) {

        auto trade = it->second;

        if (trade.getTotalProfit() > 0 &&
            trade.getTotalProfit() < secondMostProfitable->getTotalProfit() &&
            containsOnlyFreeSymbols(trade)) {
          secondMostProfitable = &trade;
        }
      }

      if (secondMostProfitable) {
        opportunitiesToQueue.push_back(secondMostProfitable);
      }

      // queue chosen opportunities for execution
      for (auto opportunity : opportunitiesToQueue) {

        // TODO: need to freeze the trades in the opportunity so that they are
        // not changed mid-execution

        // may be best to manually allocate the memory for the frozen one so it
        // can be deleted in trader

        // should ditch ITrade altogether and use Trade instead in
        // ReservedTrades? in reservedtrades for instance

        Execution independentCopy = new Execution{opportunity};
        _executionQueue.push(independentCopy);
      }
    }
  }
}