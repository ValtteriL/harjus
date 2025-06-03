#include "ReservedTrades.h"
#include "StaticTrade.h"
#include <algorithm>
#include <mutex>
#include <shared_mutex>

void ReservedTrades::reserve(const std::vector<Trade> &trades) {
  std::unique_lock<std::shared_mutex> lock(mtx);
  for (const auto &trade : trades) {
    _reservedTrades.insert(
        std::make_pair(trade.symbol()->symbol, trade.position()));
  }
}

void ReservedTrades::release(const Trade &trade) {
  std::unique_lock<std::shared_mutex> lock(mtx);
  _reservedTrades.erase(
      std::make_pair(trade.symbol()->symbol, trade.position()));
}

void ReservedTrades::release(const StaticTrade &staticTrade) {
  std::unique_lock<std::shared_mutex> lock(mtx);
  _reservedTrades.erase(
      std::make_pair(staticTrade.symbol(), staticTrade.position()));
}

void ReservedTrades::releaseAll(const std::vector<StaticTrade> &trades) {
  std::unique_lock<std::shared_mutex> lock(mtx);
  std::for_each(trades.begin(), trades.end(),
                [this](const StaticTrade &staticTrade) {
                  _reservedTrades.erase(std::make_pair(staticTrade.symbol(),
                                                       staticTrade.position()));
                });
}

bool ReservedTrades::isReserved(const Trade &trade) {
  std::shared_lock<std::shared_mutex> lock(mtx);
  return _reservedTrades.contains(
      std::make_pair(trade.symbol()->symbol, trade.position()));
}

bool ReservedTrades::isReserved(const std::vector<Trade> &trades) {
  std::shared_lock<std::shared_mutex> lock(mtx);
  return std::any_of(trades.begin(), trades.end(), [this](const Trade &trade) {
    return _reservedTrades.contains(
        std::make_pair(trade.symbol()->symbol, trade.position()));
  });
}