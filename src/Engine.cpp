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

  // update symbol price
  _symbols.at(update->symbol)->askPrice = update->askPrice;
  _symbols.at(update->symbol)->bidPrice = update->bidPrice;
  _symbols.at(update->symbol)->askQty = update->askQty;
  _symbols.at(update->symbol)->bidQty = update->bidQty;

  std::vector<Opportunity *> opportunitiesToQueue;

  // update all affected opportunities
  auto affectedOpportunitys = _opportunities.equal_range(
      update->symbol); // get all affected oppotunities

  for (auto it = affectedOpportunitys.first; it != affectedOpportunitys.second;
       ++it) {

    Opportunity &opportunity = it->second;

    auto startingAssetBudget =
        _balance.getBalance(opportunity.getStartingAsset());

    // update the opportunity with the new price
    opportunity.update(startingAssetBudget);
  }

  // find the most profitable opportunity
  Opportunity *mostProfitableOpportunity = nullptr;
  for (auto it = affectedOpportunitys.first; it != affectedOpportunitys.second;
       ++it) {

    Opportunity &opportunity = it->second;

    if (opportunity.getTotalProfit() > PreciseNumber{"0"} &&
        (!mostProfitableOpportunity ||
         opportunity.getTotalProfit() >
             mostProfitableOpportunity->getTotalProfit()) &&
        containsOnlyFreeSymbols(opportunity)) {
      mostProfitableOpportunity = &opportunity;
    }
  }

  // clean up the update
  delete update;

  // if no most profitable opportunity is found, there isn't second most
  // profitable opportunity either
  if (!mostProfitableOpportunity) {
    return;
  }

  opportunitiesToQueue.push_back(mostProfitableOpportunity);

  // lock symbols, balance for the best opportunity
  for (auto &trade : mostProfitableOpportunity->getTrades()) {
    _reservedTrades.reserve(trade);
  }
  _balance.updateBalance(mostProfitableOpportunity->getStartingAsset(),
                         mostProfitableOpportunity->getCapacity() *
                             PreciseNumber{"-1"});

  // update opportunity that use the same starting asset
  auto newBalance =
      _balance.getBalance(mostProfitableOpportunity->getStartingAsset());
  for (auto it = affectedOpportunitys.first; it != affectedOpportunitys.second;
       ++it) {

    auto &opportunity = it->second;

    // skip the most profitable opportunity
    if (opportunity.getStartingAsset() ==
            mostProfitableOpportunity->getStartingAsset() &&
        &opportunity != mostProfitableOpportunity) {
      opportunity.update(newBalance);
    }
  }

  // find the second most profitable
  Opportunity *secondMostProfitable = nullptr;
  for (auto it = affectedOpportunitys.first; it != affectedOpportunitys.second;
       ++it) {

    auto &opportunity = it->second;

    if (opportunity.getTotalProfit() > PreciseNumber{"0"} &&
        (!secondMostProfitable || opportunity.getTotalProfit() >
                                      secondMostProfitable->getTotalProfit()) &&
        containsOnlyFreeSymbols(opportunity)) {
      secondMostProfitable = &opportunity;
    }
  }

  if (secondMostProfitable) {

    // lock symbols, balance for the secnd most profitable opportunity
    for (auto &trade : secondMostProfitable->getTrades()) {
      _reservedTrades.reserve(trade);
    }
    _balance.updateBalance(secondMostProfitable->getStartingAsset(),
                           secondMostProfitable->getCapacity() *
                               PreciseNumber{"-1"});

    opportunitiesToQueue.push_back(secondMostProfitable);
  }

  // freeze and queue chosen opportunities for execution
  for (auto opportunity : opportunitiesToQueue) {

    Execution execution{*opportunity};

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