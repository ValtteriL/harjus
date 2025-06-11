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
  ArbmapperTest() {
    btcEthSymbol = new Symbol{"BTCETH",
                              "BTC",
                              "ETH",
                              PreciseNumber{"10"},
                              PreciseNumber{"0.0001"},
                              PreciseNumber{"0.01"},
                              8,
                              2,
                              PreciseNumber{"30000"},
                              PreciseNumber{"30010"},
                              PreciseNumber{"1"},
                              PreciseNumber{"1"}};
    ethDogeSymbol = new Symbol{"ETHDOGE",
                               "ETH",
                               "DOGE",
                               PreciseNumber{"10"},
                               PreciseNumber{"0.0001"},
                               PreciseNumber{"0.01"},
                               8,
                               8,
                               PreciseNumber{"0.07"},
                               PreciseNumber{"0.071"},
                               PreciseNumber{"1"},
                               PreciseNumber{"1"}};
    dogeBtcSymbol = new Symbol{"DOGEBTC",
                               "DOGE",
                               "BTC",
                               PreciseNumber{"10"},
                               PreciseNumber{"0.0001"},
                               PreciseNumber{"0.01"},
                               8,
                               8,
                               PreciseNumber{"1400"},
                               PreciseNumber{"1410"},
                               PreciseNumber{"1"},
                               PreciseNumber{"1"}};
    symbolMap["BTCETH"] = btcEthSymbol;
    symbolMap["ETHDOGE"] = ethDogeSymbol;
    symbolMap["DOGEBTC"] = dogeBtcSymbol;
  }

  ~ArbmapperTest() override {
    delete btcEthSymbol;
    delete ethDogeSymbol;
    delete dogeBtcSymbol;
  }

  MockConfiguration config;
  Symbol *btcEthSymbol;
  Symbol *ethDogeSymbol;
  Symbol *dogeBtcSymbol;
  std::unordered_map<std::string, Symbol *> symbolMap;
};

TEST_F(ArbmapperTest, noPathsWhenDepthIsZero) {
  std::vector<std::string> skipSymbols{};

  EXPECT_CALL(config, getBlacklistedStartAssets())
      .WillOnce(testing::Return(skipSymbols));
  EXPECT_CALL(config, getMaxTradingPathLength()).WillOnce(testing::Return(0));

  auto opportunities = getTradingPaths(&symbolMap, config);

  EXPECT_TRUE(opportunities.empty());
}

TEST_F(ArbmapperTest, detectsAllTradingOpportunities) {
  std::vector<std::string> skipSymbols{};

  EXPECT_CALL(config, getBlacklistedStartAssets())
      .WillOnce(testing::Return(skipSymbols));
  EXPECT_CALL(config, getMaxTradingPathLength()).WillOnce(testing::Return(3));

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

TEST_F(ArbmapperTest, excludesBlacklistedAssetsFromPaths) {
  std::vector<std::string> skipSymbols{};
  EXPECT_CALL(config, getBlacklistedStartAssets())
      .WillRepeatedly(testing::Return(skipSymbols));
  EXPECT_CALL(config, getMaxTradingPathLength())
      .WillRepeatedly(testing::Return(3));

  // Helper lambda to check that no path contains any blacklisted asset (used or
  // received)
  auto pathsDoNotContain = [](const std::vector<std::vector<Trade> *> &paths,
                              const std::vector<std::string> &blacklist) {
    for (const auto &path : paths) {
      for (const auto &trade : *path) {
        EXPECT_TRUE(std::find(blacklist.begin(), blacklist.end(),
                              trade.usedCurrency()) == blacklist.end());
        EXPECT_TRUE(std::find(blacklist.begin(), blacklist.end(),
                              trade.recvCurrency()) == blacklist.end());
      }
    }
  };

  // No blacklisted assets
  std::vector<std::string> noBlacklisted{};
  EXPECT_CALL(config, getBlacklistedAssets())
      .WillOnce(testing::Return(noBlacklisted));
  auto opportunities = getTradingPaths(&symbolMap, config);
  EXPECT_EQ(opportunities.size(), 6);
  pathsDoNotContain(opportunities, noBlacklisted);

  // Irrelevant blacklisted assets
  std::vector<std::string> irrelevantBlacklisted{"SOMETHINGELSE"};
  EXPECT_CALL(config, getBlacklistedAssets())
      .WillOnce(testing::Return(irrelevantBlacklisted));
  auto opportunities1 = getTradingPaths(&symbolMap, config);
  pathsDoNotContain(opportunities1, irrelevantBlacklisted);

  // One blacklisted asset
  std::vector<std::string> oneBlacklisted{"BTC"};
  EXPECT_CALL(config, getBlacklistedAssets())
      .WillOnce(testing::Return(oneBlacklisted));
  auto opportunities2 = getTradingPaths(&symbolMap, config);
  pathsDoNotContain(opportunities2, oneBlacklisted);
  EXPECT_TRUE(opportunities2.empty());

  // Multiple blacklisted assets
  std::vector<std::string> multiBlacklisted{"BTC", "DOGE"};
  EXPECT_CALL(config, getBlacklistedAssets())
      .WillOnce(testing::Return(multiBlacklisted));
  auto opportunities3 = getTradingPaths(&symbolMap, config);
  pathsDoNotContain(opportunities3, multiBlacklisted);
  EXPECT_TRUE(opportunities3.empty());

  // All assets blacklisted (should be zero paths)
  std::vector<std::string> allBlacklisted{"BTC", "ETH", "DOGE"};
  EXPECT_CALL(config, getBlacklistedAssets())
      .WillOnce(testing::Return(allBlacklisted));
  auto opportunities4 = getTradingPaths(&symbolMap, config);
  EXPECT_TRUE(opportunities4.empty());
}
