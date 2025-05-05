#include "Balance.h"

void Balance::updateBalance(const std::string &currency,
                            boost::multiprecision::cpp_dec_float_50 amount) {
  std::unique_lock<std::shared_mutex> lock(mtx);
  if (balanceMap.find(currency) != balanceMap.end()) {
    balanceMap[currency] += amount;
  } else {
    balanceMap[currency] = amount;
  }
}

void Balance::updateBalance(
    const std::unordered_map<
        std::string, boost::multiprecision::cpp_dec_float_50> &assetDelta) {
  std::unique_lock<std::shared_mutex> lock(mtx);
  for (const auto &[currency, amount] : assetDelta) {
    if (balanceMap.find(currency) != balanceMap.end()) {
      balanceMap[currency] += amount;
    } else {
      balanceMap[currency] = amount;
    }
  }
}

boost::multiprecision::cpp_dec_float_50
Balance::getBalance(const std::string &currency) {
  std::shared_lock<std::shared_mutex> lock(mtx);
  if (balanceMap.find(currency) != balanceMap.end()) {
    return balanceMap.at(currency);
  }
  return boost::multiprecision::cpp_dec_float_50(0);
}
