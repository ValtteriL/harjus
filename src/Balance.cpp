#include "Balance.h"

void Balance::updateBalance(const std::string &currency,
                            boost::multiprecision::cpp_dec_float_50 amount) {
  if (balanceMap.find(currency) != balanceMap.end()) {
    balanceMap[currency] += amount;
  } else {
    balanceMap[currency] = amount;
  }
}

boost::multiprecision::cpp_dec_float_50
Balance::getBalance(const std::string &currency) const {
  if (balanceMap.find(currency) != balanceMap.end()) {
    return balanceMap.at(currency);
  }
  return boost::multiprecision::cpp_dec_float_50(0);
}
