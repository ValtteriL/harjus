/*
 * ArbmapperTest.cpp
 * Testing the Arbmapper function.
 */

#include "Arbmapper.h"
#include "Configuration_test.h"
#include "PreciseNumber.h"
#include "Symbol.h"
#include "gmock/gmock.h"
#include <gtest/gtest.h>
#include <unordered_set>

/**
 * Test fixture for Engine.
 */

class ArbmapperTest : public testing::Test {
protected:
  ArbmapperTest() {}

  MockConfiguration config;
};

TEST_F(ArbmapperTest, noPathsWhenDepthIsZero) {
  // Create a vector of symbols
  std::unordered_map<std::string, Symbol *> symbolMap{};
  std::vector<std::string> skipSymbols{};

  EXPECT_CALL(config, getBlacklistedStartSymbols())
      .WillOnce(testing::Return(skipSymbols));
  EXPECT_CALL(config, getMaxTradingPathLength())
      .WillOnce(testing::Return(0));

  auto opportunities = getTradingPaths(&symbolMap, config);

  EXPECT_TRUE(opportunities.empty());
}

TEST_F(ArbmapperTest, detectsAllTradingOpportunities) {

  Symbol *btcEthSymbol = new Symbol{"BTCETH",
                                    "BTC",
                                    "ETH",
                                    PreciseNumber{"30000"},
                                    PreciseNumber{"30010"},
                                    PreciseNumber{"1"},
                                    PreciseNumber{"1"},
                                    PreciseNumber{"10"},
                                    PreciseNumber{"0.0001"},
                                    PreciseNumber{"0.01"},
                                    8,
                                    2};
  Symbol *ethDogeSymbol = new Symbol{"ETHDOGE",
                                     "ETH",
                                     "DOGE",
                                     PreciseNumber{"0.07"},
                                     PreciseNumber{"0.071"},
                                     PreciseNumber{"1"},
                                     PreciseNumber{"1"},
                                     PreciseNumber{"10"},
                                     PreciseNumber{"0.0001"},
                                     PreciseNumber{"0.01"},
                                     8,
                                     8};
  Symbol *dogeBtcSymbol = new Symbol{"DOGEBTC",
                                     "DOGE",
                                     "BTC",
                                     PreciseNumber{"1400"},
                                     PreciseNumber{"1410"},
                                     PreciseNumber{"1"},
                                     PreciseNumber{"1"},
                                     PreciseNumber{"10"},
                                     PreciseNumber{"0.0001"},
                                     PreciseNumber{"0.01"},
                                     8,
                                     8};

  // Create a vector of symbols
  std::unordered_map<std::string, Symbol *> symbolMap{
      {"BTCETH", btcEthSymbol},
      {"ETHDOGE", ethDogeSymbol},
      {"DOGEBTC", dogeBtcSymbol}};

  std::vector<std::string> skipSymbols{};

  EXPECT_CALL(config, getBlacklistedStartSymbols())
      .WillOnce(testing::Return(skipSymbols));
  EXPECT_CALL(config, getMaxTradingPathLength())
      .WillOnce(testing::Return(3));

  auto opportunities = getTradingPaths(&symbolMap, config);

  // Print out the detected opportunities with symbols and positions
  for (const auto &path : opportunities) {
    std::cout << "Path: ";
    for (const auto &trade : *path) {
      auto position = trade.position() == Position::LONG ? "LONG" : "SHORT";
      std::cout << trade.symbol()->symbol << " (" << position << ") ";
    }
    std::cout << std::endl;
  }

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
    firstUsedCurrencies.insert(std::string{path->front().usedCurrency()});
  }
  EXPECT_TRUE(firstUsedCurrencies.count("BTC"));
  EXPECT_TRUE(firstUsedCurrencies.count("ETH"));
  EXPECT_TRUE(firstUsedCurrencies.count("DOGE"));

  // Additional checks for path consistency
  for (const auto &path : opportunities) {
    // 1. For every trade except the first, usedCurrency == previous trade's
    // recvCurrency
    for (size_t i = 1; i < path->size(); ++i) {
      EXPECT_EQ(path->at(i).usedCurrency(), path->at(i - 1).recvCurrency());
    }

    // 3. Starting asset is the same as recvCurrency of the last trade
    std::string startingAsset = path->front().usedCurrency();
    std::string lastRecvCurrency = path->back().recvCurrency();
    EXPECT_EQ(startingAsset, lastRecvCurrency);
  }
}
