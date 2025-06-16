#pragma once

#include "PreciseNumber.h"
#include <shared_mutex>
#include <unordered_map>

/**
 * Balance class. Contains logic for accounting balance.
 * This class is used to keep track of the balance during trading.
 */

class Balance {
private:
  /**
   *  Balance map
   */
  std::unordered_map<std::string, PreciseNumber> balanceMap;

  /**
   * Mutex for thread safety.
   */
  mutable std::shared_mutex mtx;

public:
  /**
   *  Add a currency to the balance.
   *  This is used to increment and decrement the balance for a currency.
   *  If the currency is not present in the map, it will be added.
   *  If the currency is present, the amount will be added to the existing
   * balance. If the amount is negative, it will be subtracted from the existing
   * balance.
   *  @param currency The currency to add.
   *  @param amount The amount to add.
   */
  void updateBalance(const std::string &currency, const PreciseNumber &amount);

  /**
   *  Add a currency to the balance.
   *  This is used to increment and decrement the balance for a currency.
   *  If the currency is not present in the map, it will be added.
   *  If the currency is present, the amount will be added to the existing
   * balance. If the amount is negative, it will be subtracted from the existing
   * balance.
   *  @param assetDelta The map of currencies and amounts to add.
   */
  void
  updateBalance(std::unordered_map<std::string, PreciseNumber> &assetDelta);

  /**
   *  Get all balances.
   *  This is used to get the current balances for all currencies.
   */
  std::unordered_map<std::string, PreciseNumber> getBalances() const;
};