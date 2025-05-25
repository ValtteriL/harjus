#include "ReservedTrades.h"
#include "StaticTrade.h"
#include <mutex>
#include <shared_mutex>

void ReservedTrades::reserve(const Trade &trade) {
  std::unique_lock<std::shared_mutex> lock(mtx);
  _reservedTrades.insert(
      std::make_pair(trade.symbol()->symbol, trade.position()));
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
  for (auto &staticTrade : trades) {
    _reservedTrades.erase(
        std::make_pair(staticTrade.symbol(), staticTrade.position()));
  }
}

bool ReservedTrades::isReserved(const Trade &trade) {
  std::shared_lock<std::shared_mutex> lock(mtx);
  return _reservedTrades.contains(
      std::make_pair(trade.symbol()->symbol, trade.position()));
}

bool ReservedTrades::isReserved(const std::vector<Trade> &trades) {
  std::shared_lock<std::shared_mutex> lock(mtx);
  for (auto &trade : trades) {
    if (_reservedTrades.contains(
            std::make_pair(trade.symbol()->symbol, trade.position()))) {
      return true;
    }
  }
  return false;
}