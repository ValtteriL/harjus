/*
 * ArbmapperTest.cpp
 * Testing the Arbmapper function.
 */

#include <gtest/gtest.h>
#include "Arbmapper.h"
#include <unordered_set>

TEST(ArbmapperTest, detectOpportunities)
{
  // Create a vector of symbols
  std::vector<Symbol> symbols{};
  int depth = 3;
  std::vector<Symbol> skipSymbols{};
  auto opportunities = getTradingPaths(symbols, depth, skipSymbols);

  EXPECT_TRUE(false);
}
