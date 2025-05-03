#include "ReservedTrades.h"

void ReservedTrades::reserve(Trade &trade) { reservedTrades.insert(&trade); }

void ReservedTrades::release(Trade &trade) { reservedTrades.erase(&trade); }

void ReservedTrades::releaseAll(std::vector<Trade *> &trades) {
  for (auto trade : trades) {
    reservedTrades.erase(trade);
  }
}

bool ReservedTrades::isReserved(Trade &trade) const {
  return reservedTrades.contains(&trade);
}
