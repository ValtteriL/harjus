#include "ReservedTrades.h"

void ReservedTrades::reserve(Trade &trade) {
  std::lock_guard<std::mutex> lock(mtx);
  reservedTrades.insert(&trade);
}

void ReservedTrades::release(Trade &trade) {
  std::lock_guard<std::mutex> lock(mtx);
  reservedTrades.erase(&trade);
}

void ReservedTrades::releaseAll(std::vector<Trade *> &trades) {
  std::lock_guard<std::mutex> lock(mtx);
  for (auto trade : trades) {
    reservedTrades.erase(trade);
  }
}

bool ReservedTrades::isReserved(Trade &trade) {
  std::lock_guard<std::mutex> lock(mtx);
  return reservedTrades.contains(&trade);
}
