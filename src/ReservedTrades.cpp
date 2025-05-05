#include "ReservedTrades.h"
#include <mutex>
#include <shared_mutex>

void ReservedTrades::reserve(Trade &trade) {
  std::unique_lock<std::shared_mutex> lock(mtx);
  reservedTrades.insert(&trade);
}

void ReservedTrades::release(Trade &trade) {
  std::unique_lock<std::shared_mutex> lock(mtx);
  reservedTrades.erase(&trade);
}

void ReservedTrades::releaseAll(std::vector<Trade> &trades) {
  std::unique_lock<std::shared_mutex> lock(mtx);
  for (auto &trade : trades) {
    reservedTrades.erase(&trade);
  }
}

bool ReservedTrades::isReserved(Trade &trade) {
  std::shared_lock<std::shared_mutex> lock(mtx);
  return reservedTrades.contains(&trade);
}

bool ReservedTrades::isReserved(std::vector<Trade> &trades) {
  std::shared_lock<std::shared_mutex> lock(mtx);
  for (auto &trade : trades) {
    if (reservedTrades.contains(&trade)) {
      return true;
    }
  }
  return false;
}