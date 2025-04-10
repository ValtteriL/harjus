/*
 * ArbmapperTest.cpp
 * Testing the Arbmapper function.
 */

#include <gtest/gtest.h>
#include "Arbmapper.h"
#include <unordered_set>

TEST(ArbmapperTest, noPathsWhenDepthIsZero)
{
  // Create a vector of symbols
  std::unordered_map<std::string, Symbol> symbolMap{};
  int depth = 0;
  std::vector<std::string> skipSymbols{};
  auto opportunities = getTradingPaths(&symbolMap, depth, skipSymbols);

  EXPECT_TRUE(opportunities.empty());
}

TEST(ArbmapperTest, detectsAllTradingOpportunities)
{
  // Create a vector of symbols
  std::unordered_map<std::string, Symbol> symbolMap{
      {"BTCUSDT", {"BTCUSDT", "BTC", "USDT", 30000, 30010, 1, 1, 10, 0.0001, 0.01, 8, 2}},
      {"ETHBTC", {"ETHBTC", "ETH", "BTC", 0.07, 0.071, 1, 1, 10, 0.0001, 0.01, 8, 8}},
      {"USDTETH", {"USDTETH", "USDT", "ETH", 1400, 1410, 1, 1, 10, 0.0001, 0.01, 8, 8}}};

  int depth = 3;
  std::vector<std::string> skipSymbols{};
  auto opportunities = getTradingPaths(&symbolMap, depth, skipSymbols);

  // Verify that opportunities are detected
  EXPECT_FALSE(opportunities.empty());

  // Verify that all paths are within the depth limit
  for (const auto &path : opportunities)
  {
    EXPECT_LE(path.size(), depth);
  }

  // Verify that the returned trading paths contain at least one path
  // with each of the following as the first usedCurrency: BTC, ETH, USDT
  std::unordered_set<std::string> firstUsedCurrencies;
  for (const auto &path : opportunities)
  {
    firstUsedCurrencies.insert(std::string{path.front().getUsedCurrency()});
  }
  EXPECT_TRUE(firstUsedCurrencies.count("BTC"));
  EXPECT_TRUE(firstUsedCurrencies.count("ETH"));
  EXPECT_TRUE(firstUsedCurrencies.count("USDT"));
}
