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
               ThreadSafeQueue<PriceUpdate> &priceUpdateQueue,
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
      _opportunities.insert({trade.symbol()->symbol, opportunity});
    }
  }
};

bool Engine::containsOnlyFreeSymbols(const Opportunity *opportunity) {
  return !_reservedTrades.isReserved(opportunity->getTrades());
}

void Engine::reserveBudgetAndSymbols(Opportunity &opp) {
  _reservedTrades.reserve(opp.getTrades());
  _balance.updateBalance(opp.getStartingAsset(),
                         opp.getCapacity() * PreciseNumber{"-1"});
}

void Engine::processPriceUpdate(const PriceUpdate &update) {
  // Update symbol price
  update.symbol->askPrice = update.askPrice;
  update.symbol->bidPrice = update.bidPrice;
  update.symbol->askQty = update.askQty;
  update.symbol->bidQty = update.bidQty;

  // Update all affected opportunities
  auto affected = _opportunities.equal_range(update.symbol->symbol);
  for (auto it = affected.first; it != affected.second; ++it) {
    Opportunity *opp = it->second;
    auto startingAssetBudget = _balance.getBalance(opp->getStartingAsset());
    opp->update(startingAssetBudget);
  }

  // find the 2 most profitable opportunities, reserve budget and symbols, and
  // queue them for execution
  for (int i = 0; i < 2; ++i) {

    Opportunity *best = nullptr;
    best = findMostProfitable(affected.first, affected.second, best);

    if (!best)
      return;

    reserveBudgetAndSymbols(*best);

    // Freeze and queue the best opportunity for execution
    Execution execution{*best};
    BOOST_LOG_TRIVIAL(debug) << "Queuing execution for trader: " << execution;
    _executionQueue.push(std::move(execution));

    // Update opportunities that use the same starting asset
    auto newBalance = _balance.getBalance(best->getStartingAsset());
    for (auto it = affected.first; it != affected.second; ++it) {
      Opportunity *opp = it->second;
      if (opp->getStartingAsset() == best->getStartingAsset() && opp != best) {
        opp->update(newBalance);
      }
    }
  }
}

Opportunity *Engine::findMostProfitable(
    std::unordered_multimap<std::string, Opportunity *>::iterator begin,
    std::unordered_multimap<std::string, Opportunity *>::iterator end,
    Opportunity *exclude) {
  Opportunity *best = nullptr;
  for (auto it = begin; it != end; ++it) {
    Opportunity *opp = it->second;
    if ((exclude == nullptr || opp != exclude) &&
        opp->getTotalProfit() > PreciseNumber{"0"} &&
        (!best || opp->getTotalProfit() > best->getTotalProfit()) &&
        containsOnlyFreeSymbols(opp)) {
      best = opp;
    }
  }
  return best;
}

void Engine::run(std::stop_token stoken) {

  BOOST_LOG_TRIVIAL(debug) << "Starting Engine";

  while (!stoken.stop_requested()) {

    if (_priceUpdateQueue.getSemaphore().try_acquire_for(
            std::chrono::milliseconds{100})) {
      if (PriceUpdate update; _priceUpdateQueue.try_pop(update)) {
        BOOST_LOG_TRIVIAL(trace) << "Ingesting price update: " << update;
        processPriceUpdate(update);
      }
    }
  }

  BOOST_LOG_TRIVIAL(debug) << "Stopping Engine";
}