#include "ReservedTrades.h"
#include "StaticTrade.h"
#include <algorithm>

void ReservedTrades::reserveAll(const std::vector<Trade> &trades) {
  for (const auto &trade : trades) {
    _reservedTrades.insert(trade.symbol()->symbol);
  }
}

void ReservedTrades::releaseAll(const std::vector<StaticTrade> &trades) {
  std::for_each(trades.begin(), trades.end(),
                [this](const StaticTrade &staticTrade) {
                  _reservedTrades.erase(staticTrade.symbol());
                });
}

auto ReservedTrades::getReservedTrades() const
    -> const std::unordered_set<std::string> & {
  return _reservedTrades;
}