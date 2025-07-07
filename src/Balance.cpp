#include "Balance.h"
#include "PreciseNumber.h"

void Balance::updateBalance(const std::string &currency,
                            const PreciseNumber &amount) {
  balanceMap[currency] += amount;
}

void Balance::updateBalance(
    std::unordered_map<std::string, PreciseNumber> &assetDelta) {
  std::for_each(assetDelta.begin(), assetDelta.end(), [this](const auto &pair) {
    balanceMap[pair.first] += pair.second;
  });
}

auto Balance::getBalances() const
    -> const std::unordered_map<std::string, PreciseNumber> {
  return balanceMap;
}
