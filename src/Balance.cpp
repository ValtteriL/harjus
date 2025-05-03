#include "Balance.h"

void Balance::updateBalance(const std::string &currency,
                            boost::multiprecision::cpp_dec_float_50 amount) {
  std::lock_guard<std::mutex> lock(mtx);
  if (balanceMap.find(currency) != balanceMap.end()) {
    balanceMap[currency] += amount;
  } else {
    balanceMap[currency] = amount;
  }
}

void Balance::updateBalance(
    const std::unordered_map<
        std::string, boost::multiprecision::cpp_dec_float_50> &assetDelta) {
  std::lock_guard<std::mutex> lock(mtx);
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
  std::lock_guard<std::mutex> lock(mtx);
  if (balanceMap.find(currency) != balanceMap.end()) {
    return balanceMap.at(currency);
  }
  return boost::multiprecision::cpp_dec_float_50(0);
}
