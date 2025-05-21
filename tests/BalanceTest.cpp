/*
 * BalanceTest.cpp
 * Testing the Balance class.
 */

#include "Balance.h"
#include <gtest/gtest.h>

TEST(BalanceTest, insertUpdateBalance) {
  // By default, the balance is 0
  Balance balance;
  std::string currency = "BTC";

  EXPECT_EQ(balance.getBalance(currency), 0);

  // Add 1 BTC to the balance
  balance.updateBalance(currency, 1);
  EXPECT_EQ(balance.getBalance(currency), 1);

  // Decrease the balance by 0.5 BTC
  balance.updateBalance(currency, -0.5);
  EXPECT_EQ(balance.getBalance(currency), 0.5);

  // Balance of other currencies is not affected
  std::string currency2 = "ETH";
  EXPECT_EQ(balance.getBalance(currency2), 0);
}

TEST(BalanceTest, updateBalanceMap) {
  Balance balance;
  std::unordered_map<std::string, PreciseNumber> assetDelta = {{"BTC", 1},
                                                               {"ETH", 2}};

  // Update balance with assetDelta
  balance.updateBalance(assetDelta);

  // Check the balances
  EXPECT_EQ(balance.getBalance("BTC"), 1);
  EXPECT_EQ(balance.getBalance("ETH"), 2);

  // Update balance with negative assetDelta
  assetDelta = {{"BTC", -0.5}, {"ETH", -1}};

  balance.updateBalance(assetDelta);

  EXPECT_EQ(balance.getBalance("BTC"), 0.5);
  EXPECT_EQ(balance.getBalance("ETH"), 1);
}