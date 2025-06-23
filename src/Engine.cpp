#include "Engine.h"
#include "Execution.h"
#include "Opportunity.h"
#include "ReservedTrades.h"
#include <algorithm>
#include <boost/log/core.hpp>
#include <boost/log/expressions.hpp>
#include <boost/log/trivial.hpp>
#include <stop_token>
#include <string>
#include <vector>

Engine::Engine(std::unordered_map<std::string, Symbol> &symbols,
               std::vector<std::vector<Trade> *> &tradingPaths,
               Balance &balance, ReservedTrades &reservedTrades,
               boost::lockfree::spsc_queue<PriceUpdate> &priceUpdateQueue,
               boost::lockfree::spsc_queue<Execution> &executionQueue,
               std::unordered_map<std::string, PreciseNumber> &relativeValues,
               const PreciseNumber &commission)
    : _symbols(&symbols), _relativeValues(relativeValues),
      _priceUpdateQueue(&priceUpdateQueue), _executionQueue(&executionQueue),
      _reservedTrades(&reservedTrades), _balance(&balance) {

  // Initialize _opportunities with the trading paths
  for (auto &path : tradingPaths) {

    // create an opportunity
    std::string startingAsset = path->front().usedCurrency();
    auto *opportunity =
        new Opportunity(*path, _relativeValues[startingAsset], commission);

    // add opportunity to _opportunities with every trade symbol as the key
    for (auto &trade : *path) {
      _opportunities.insert({trade.symbol()->symbol, opportunity});
    }
  }
};

void Engine::reserveBudgetAndSymbols(const Opportunity &opp) {
  _reservedTrades->reserveAll(opp.getTrades());
  _balance->updateBalance(opp.getStartingAsset(),
                          opp.getCapacity() * PreciseNumber{"-1"});
}

void Engine::processPriceUpdate(const PriceUpdate &update) {
  // Update symbol price
  update.symbol->askPrice = update.askPrice;
  update.symbol->bidPrice = update.bidPrice;
  update.symbol->askQty = update.askQty;
  update.symbol->bidQty = update.bidQty;

  // get balances
  auto balanceMap = _balance->getBalances();

  // get reserved trades
  auto reservedSymbols = _reservedTrades->getReservedTrades();

  Opportunity *best = nullptr;

  // Update all affected opportunities
  auto affected = _opportunities.equal_range(update.symbol->symbol);
  for (auto it = affected.first; it != affected.second; ++it) {

    auto opp = it->second;

    // Update the opportunity with the new price
    opp->update(balanceMap[opp->getStartingAsset()]);

    if (PreciseNumber{"0"} >= opp->getTotalProfit() ||
        std::any_of(opp->getTrades().begin(), opp->getTrades().end(),
                    [&reservedSymbols](const StaticTrade &trade) {
                      return reservedSymbols.contains(trade.symbol());
                    }))
      continue;

    // If the opportunity is profitable and does not contain reserved symbols,
    // check if it's the best one
    if (!best || opp->getTotalProfit() > best->getTotalProfit()) {
      best = opp;
    }
  }

  if (!best)
    return;

  reserveBudgetAndSymbols(*best);

  // Freeze and queue the best opportunity for execution
  Execution execution{*best};
  BOOST_LOG_TRIVIAL(debug) << "Queuing execution for trader: " << execution;
  _executionQueue->push(std::move(execution));
}

void Engine::run(const std::stop_token &stoken) {

  BOOST_LOG_TRIVIAL(debug) << "Starting Engine";

  while (!stoken.stop_requested()) {

    if (PriceUpdate update; _priceUpdateQueue->pop(update)) {
      processPriceUpdate(update);
    }
  }

  BOOST_LOG_TRIVIAL(debug) << "Stopping Engine";
}