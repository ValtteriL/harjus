#include "Balance.h"
#include "PreciseNumber.h"

void Balance::updateBalance(const std::string &currency,
                            const PreciseNumber &amount) {
  std::unique_lock<std::shared_mutex> lock(mtx);
  balanceMap[currency] += amount;
}

void Balance::updateBalance(
    std::unordered_map<std::string, PreciseNumber> &assetDelta) {
  std::unique_lock<std::shared_mutex> lock(mtx);
  std::for_each(assetDelta.begin(), assetDelta.end(), [this](const auto &pair) {
    balanceMap[pair.first] += pair.second;
  });
}

auto Balance::getBalances() const
    -> std::unordered_map<std::string, PreciseNumber> {
  std::shared_lock<std::shared_mutex> lock(mtx);
  return balanceMap;
}
