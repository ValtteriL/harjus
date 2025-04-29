#include "Engine.h"
#include "Execution.h"
#include <string>

Engine::Engine(
    std::unordered_map<std::string, Symbol> &symbols,
    std::vector<std::vector<Trade> *> &tradingPaths, Balance &balance,
    ReservedTrades &reservedTrades,
    boost::lockfree::queue<PriceUpdate> &priceUpdateQueue,
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

void Engine::run() {}