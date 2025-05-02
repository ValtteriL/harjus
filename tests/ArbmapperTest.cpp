/*
 * ArbmapperTest.cpp
 * Testing the Arbmapper function.
 */

#include "Arbmapper.h"
#include "Symbol.h"
#include <gtest/gtest.h>
#include <unordered_set>

TEST(ArbmapperTest, noPathsWhenDepthIsZero) {
  // Create a vector of symbols
  std::unordered_map<std::string, Symbol *> symbolMap{};
  int depth = 0;
  std::vector<std::string> skipSymbols{};
  auto opportunities = getTradingPaths(&symbolMap, depth, skipSymbols);

  EXPECT_TRUE(opportunities.empty());
}

TEST(ArbmapperTest, detectsAllTradingOpportunities) {

  Symbol *btcEthSymbol = new Symbol{"BTCETH", "BTC", "ETH",  30000, 30010, 1,
                                    1,        10,    0.0001, 0.01,  8,     2};
  Symbol *ethDogeSymbol = new Symbol{"ETHDOGE", "ETH", "DOGE", 0.07, 0.071, 1,
                                     1,         10,    0.0001, 0.01, 8,     8};
  Symbol *dogeBtcSymbol = new Symbol{"DOGEBTC", "DOGE", "BTC",  1400, 1410, 1,
                                     1,         10,     0.0001, 0.01, 8,    8};

  // Create a vector of symbols
  std::unordered_map<std::string, Symbol *> symbolMap{
      {"BTCETH", btcEthSymbol},
      {"ETHDOGE", ethDogeSymbol},
      {"DOGEBTC", dogeBtcSymbol}};

  int depth = 3;
  std::vector<std::string> skipSymbols{};
  auto opportunities = getTradingPaths(&symbolMap, depth, skipSymbols);

  // Verify that 6 opportunities are detected
  EXPECT_EQ(opportunities.size(), 6);

  // Verify that all paths are of length 3
  for (const auto &path : opportunities) {
    EXPECT_EQ(path->size(), 3);
  }

  // Verify that no trades are the same object (their addresses are different)
  int totalTrades = 0;
  for (const auto &path : opportunities) {
    totalTrades += path->size();
  }
  std::unordered_set<std::string> uniqueTradeAddresses;
  for (const auto &path : opportunities) {
    for (const auto &trade : *path) {
      uniqueTradeAddresses.insert(
          std::to_string(reinterpret_cast<std::uintptr_t>(&trade)));
    }
  }
  EXPECT_EQ(uniqueTradeAddresses.size(), totalTrades);

  // Verify that the returned trading paths contain at least one path
  // with each of the following as the first usedCurrency: BTC, ETH, DOGE
  std::unordered_set<std::string> firstUsedCurrencies;
  for (const auto &path : opportunities) {
    firstUsedCurrencies.insert(std::string{path->front().getUsedCurrency()});
  }
  EXPECT_TRUE(firstUsedCurrencies.count("BTC"));
  EXPECT_TRUE(firstUsedCurrencies.count("ETH"));
  EXPECT_TRUE(firstUsedCurrencies.count("DOGE"));
}
