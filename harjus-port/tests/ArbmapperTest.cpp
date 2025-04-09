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
  std::unordered_map<std::string, Symbol> symbolMap{};
  int depth = 3;
  std::vector<std::string> skipSymbols{};
  auto opportunities = getTradingPaths(&symbolMap, depth, skipSymbols);

  EXPECT_TRUE(false);
}
