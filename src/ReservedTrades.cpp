#include "ReservedTrades.h"
#include "StaticTrade.h"
#include <algorithm>
#include <mutex>
#include <shared_mutex>

void ReservedTrades::reserveAll(const std::vector<Trade> &trades) {
  std::unique_lock<std::shared_mutex> lock(mtx);
  for (const auto &trade : trades) {
    _reservedTrades.insert(trade.symbol()->symbol);
  }
}

void ReservedTrades::releaseAll(const std::vector<StaticTrade> &trades) {
  std::unique_lock<std::shared_mutex> lock(mtx);
  std::for_each(trades.begin(), trades.end(),
                [this](const StaticTrade &staticTrade) {
                  _reservedTrades.erase(staticTrade.symbol());
                });
}

auto ReservedTrades::getReservedTrades() const
    -> std::unordered_set<std::string> {
  std::shared_lock<std::shared_mutex> lock(mtx);
  return _reservedTrades;
}