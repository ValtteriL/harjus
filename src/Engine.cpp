#include "Engine.h"
#include "Execution.h"
#include "Opportunity.h"
#include "ReservedTrades.h"
#include <algorithm>
#include <boost/log/core.hpp>
#include <boost/log/expressions.hpp>
#include <boost/log/trivial.hpp>
#include <ranges>
#include <stop_token>
#include <string>
#include <vector>

Engine::Engine(std::unordered_map<std::string, Symbol *> &symbols,
               std::vector<std::vector<Trade> *> &tradingPaths,
               Balance &balance, ReservedTrades &reservedTrades,
               boost::lockfree::spsc_queue<PriceUpdate> &priceUpdateQueue,
               boost::lockfree::spsc_queue<Execution> &executionQueue,
               std::unordered_map<std::string, PreciseNumber> &relativeValues,
               const PreciseNumber commission)
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

void Engine::reserveBudgetAndSymbols(const Opportunity &opp) {
  _reservedTrades.reserveAll(opp.getTrades());
  _balance.updateBalance(opp.getStartingAsset(),
                         opp.getCapacity() * PreciseNumber{"-1"});
}

void Engine::processPriceUpdate(const PriceUpdate &update) {
  // Update symbol price
  update.symbol->askPrice = update.askPrice;
  update.symbol->bidPrice = update.bidPrice;
  update.symbol->askQty = update.askQty;
  update.symbol->bidQty = update.bidQty;

  // get balances
  auto balanceMap = _balance.getBalances();

  // get reserved trades
  auto reservedSymbols = _reservedTrades.getReservedTrades();

  // Update all affected opportunities
  auto affected = _opportunities.equal_range(update.symbol->symbol);
  for (auto it = affected.first; it != affected.second; ++it) {
    Opportunity *opp = it->second;
    opp->update(balanceMap[opp->getStartingAsset()]);
  }

  // find the most profitable opportunity, reserve budget and symbols, and
  // queue it for execution

  // filter out opportunities that are not profitable or contain reserved
  // symbols
  auto affected_range = std::ranges::subrange(affected.first, affected.second);
  auto filtered =
      affected_range |
      std::ranges::views::filter([&reservedSymbols](const auto &pair) {
        Opportunity *opp = pair.second;
        return opp->getTotalProfit() > PreciseNumber{"0"} &&
               std::none_of(opp->getTrades().begin(), opp->getTrades().end(),
                            [&reservedSymbols](const StaticTrade &trade) {
                              return reservedSymbols.contains(trade.symbol());
                            });
      });

  auto bestIt = std::max_element(
      filtered.begin(), filtered.end(), [](const auto &a, const auto &b) {
        return a.second->getTotalProfit() < b.second->getTotalProfit();
      });
  Opportunity *best = (bestIt != filtered.end()) ? bestIt->second : nullptr;

  if (!best)
    return;

  reserveBudgetAndSymbols(*best);

  // Freeze and queue the best opportunity for execution
  Execution execution{*best};
  BOOST_LOG_TRIVIAL(debug) << "Queuing execution for trader: " << execution;
  _executionQueue.push(std::move(execution));
}

void Engine::run(std::stop_token stoken) {

  BOOST_LOG_TRIVIAL(debug) << "Starting Engine";

  while (!stoken.stop_requested()) {

    if (PriceUpdate update; _priceUpdateQueue.pop(update)) {
      BOOST_LOG_TRIVIAL(trace) << "Ingesting price update: " << update;
      processPriceUpdate(update);
    }
  }

  BOOST_LOG_TRIVIAL(debug) << "Stopping Engine";
}