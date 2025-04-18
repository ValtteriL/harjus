#pragma once

#include <unordered_map>
#include <boost/multiprecision/cpp_dec_float.hpp>

/**
 * Balance class. Contains logic for accounting balance.
 * This class is used to keep track of the balance during trading.
 */

class Balance
{
private:
  /**
   *  Balance map
   */
  std::unordered_map<std::string, boost::multiprecision::cpp_dec_float_50> balanceMap;

public:
  /**
   *  Add a currency to the balance.
   *  This is used to increment and decrement the balance for a currency.
   *  If the currency is not present in the map, it will be added.
   *  If the currency is present, the amount will be added to the existing balance.
   *  If the amount is negative, it will be subtracted from the existing balance.
   *  @param currency The currency to add.
   *  @param amount The amount to add.
   */
  void updateBalance(const std::string &currency, boost::multiprecision::cpp_dec_float_50 amount);

  /**
   *  Get the balance for a currency.
   *  This is used to get the balance for a currency.
   *  If the currency is not present in the map, it will return 0.
   *  @param currency The currency to get the balance for.
   */
  boost::multiprecision::cpp_dec_float_50 getBalance(const std::string &currency) const;
};