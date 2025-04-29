#pragma once

#include "Balance.h"
#include "Execution.h"
#include "PriceUpdate.h"
#include "ReservedTrades.h"
#include "Symbol.h"
#include "Trade.h"
#include <string>
#include <unordered_map>

#include <boost/lockfree/queue.hpp>
#include <boost/multiprecision/cpp_dec_float.hpp>
#include <vector>

/**
 * @brief The Engine class is responsible for spotting profitable arbitrage
 * opportunities and queuing them for Trader
 * @details Engine subscribes to priceUpdateQueue. As price updates are
 * received, it checks affected executions for arbitrage opportunities. If
 * opportunities are found, the best 2 non-overlapping are queued to the
 * executionQueue.
 */
class Engine {

private:
  std::unordered_map<std::string, Symbol> &_symbols;
  std::unordered_multimap<std::string, Execution &> _executions;
  std::unordered_map<std::string, boost::multiprecision::cpp_dec_float_50>
      _relativeValues;
  boost::lockfree::queue<PriceUpdate *> &_priceUpdateQueue;
  boost::lockfree::queue<Execution> &_executionQueue;
  ReservedTrades &_reservedTrades;
  Balance &_balance;

public:
  /**
   * @brief Constructor for the Engine class.
   * @param symbols A reference to a map of symbols.
   * @param tradingPaths A reference to a vector of trading paths.
   * @param balance A reference to a Balance object.
   * @param reservedTrades A reference to a ReservedTrades object.
   * @param priceUpdateQueue A reference to a lock-free queue for price updates.
   * @param executionQueue A reference to a lock-free queue for executions.
   * @param relativeValues A map of relative values for symbols.
   */
  Engine(
      std::unordered_map<std::string, Symbol> &symbols,
      std::vector<std::vector<Trade> *> &tradingPaths, Balance &balance,
      ReservedTrades &reservedTrades,
      boost::lockfree::queue<PriceUpdate> &priceUpdateQueue,
      boost::lockfree::queue<Execution> &executionQueue,
      std::unordered_map<std::string, boost::multiprecision::cpp_dec_float_50>
          relativeValues,
      boost::multiprecision::cpp_dec_float_50 commission);

  /**
   * @brief Run the engine
   * @details This function is the main loop of the engine.
   */
  void run();
};