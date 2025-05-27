#include "Engine.h"
#include "Execution.h"
#include "Opportunity.h"
#include <boost/log/core.hpp>
#include <boost/log/expressions.hpp>
#include <boost/log/trivial.hpp>
#include <stop_token>
#include <string>
#include <vector>

Engine::Engine(std::unordered_map<std::string, Symbol *> &symbols,
               std::vector<std::vector<Trade> *> &tradingPaths,
               Balance &balance, ReservedTrades &reservedTrades,
               boost::lockfree::queue<PriceUpdate *> &priceUpdateQueue,
               ThreadSafeQueue<Execution> &executionQueue,
               std::unordered_map<std::string, PreciseNumber> relativeValues,
               PreciseNumber commission)
    : _symbols(symbols), _relativeValues(relativeValues),
      _priceUpdateQueue(priceUpdateQueue), _executionQueue(executionQueue),
      _reservedTrades(reservedTrades), _balance(balance) {

  // Initialize _opportunities with the trading paths
  for (auto &path : tradingPaths) {

    // create an opportunity
    std::string startingAsset = path->front().usedCurrency();
    Opportunity *opportunity =
        new Opportunity(*path, _relativeValues[startingAsset], commission);

    // add opportunity to _opportunities with every trade symbol as the key
    for (auto &trade : *path) {
      _opportunities.insert({trade.symbol()->symbol, *opportunity});
    }
  }
};

bool Engine::containsOnlyFreeSymbols(Opportunity &opportunity) {
  return !_reservedTrades.isReserved(opportunity.getTrades());
}

void Engine::processPriceUpdate(const PriceUpdate *update) {
  // Update symbol price
  _symbols.at(update->symbol)->askPrice = update->askPrice;
  _symbols.at(update->symbol)->bidPrice = update->bidPrice;
  _symbols.at(update->symbol)->askQty = update->askQty;
  _symbols.at(update->symbol)->bidQty = update->bidQty;

  // Helper: Reserve all trades and budget for an opportunity
  auto reserveBudgetAndSymbols = [&](Opportunity &opp) {
    for (auto &trade : opp.getTrades()) {
      _reservedTrades.reserve(trade);
    }
    _balance.updateBalance(opp.getStartingAsset(),
                           opp.getCapacity() * PreciseNumber{"-1"});
  };

  // Update all affected opportunities
  auto affected = _opportunities.equal_range(update->symbol);
  for (auto it = affected.first; it != affected.second; ++it) {
    Opportunity &opp = it->second;
    auto startingAssetBudget = _balance.getBalance(opp.getStartingAsset());
    opp.update(startingAssetBudget);
  }

  // Find the most profitable opportunity
  Opportunity *best = nullptr;
  for (auto it = affected.first; it != affected.second; ++it) {
    Opportunity &opp = it->second;
    if (opp.getTotalProfit() > PreciseNumber{"0"} &&
        (!best || opp.getTotalProfit() > best->getTotalProfit()) &&
        containsOnlyFreeSymbols(opp)) {
      best = &opp;
    }
  }

  delete update;
  if (!best)
    return;

  std::vector<Opportunity *> toQueue;
  toQueue.push_back(best);
  reserveBudgetAndSymbols(*best);

  // Update opportunities that use the same starting asset
  auto newBalance = _balance.getBalance(best->getStartingAsset());
  for (auto it = affected.first; it != affected.second; ++it) {
    Opportunity &opp = it->second;
    if (opp.getStartingAsset() == best->getStartingAsset() && &opp != best) {
      opp.update(newBalance);
    }
  }

  // Find the second most profitable
  Opportunity *secondBest = nullptr;
  for (auto it = affected.first; it != affected.second; ++it) {
    Opportunity &opp = it->second;
    if (opp.getTotalProfit() > PreciseNumber{"0"} &&
        (!secondBest || opp.getTotalProfit() > secondBest->getTotalProfit()) &&
        containsOnlyFreeSymbols(opp)) {
      secondBest = &opp;
    }
  }

  if (secondBest) {
    reserveBudgetAndSymbols(*secondBest);
    toQueue.push_back(secondBest);
  }

  // Freeze and queue chosen opportunities for execution
  for (auto *opp : toQueue) {
    Execution execution{*opp};
    BOOST_LOG_TRIVIAL(debug) << "Queuing execution for trader: " << execution;
    _executionQueue.push(std::move(execution));
  }
}

void Engine::run(std::stop_token stoken) {

  BOOST_LOG_TRIVIAL(debug) << "Starting Engine";

  PriceUpdate *update = nullptr;

  while (!stoken.stop_requested()) {
    if (_priceUpdateQueue.pop(update)) {
      BOOST_LOG_TRIVIAL(trace) << "Ingesting price update: " << *update;
      processPriceUpdate(update);
    }
  }

  BOOST_LOG_TRIVIAL(debug) << "Stopping Engine";
}