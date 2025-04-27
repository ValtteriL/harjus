/*
 * ExchangeTest.cpp
 * Testing the Exchange class.
 */

#include "Exchange.h"
#include "Configuration_test.h"
#include <gtest/gtest.h>
#include <unordered_set>

using ::testing::Return;

/**
 * Test fixture.
 */

class ExchangeTest : public testing::Test {
protected:
  ExchangeTest() {
    EXPECT_CALL(config, getBinanceRESTApiUri())
        .WillOnce(Return("https://testnet.binance.vision"));
  }

  MockConfiguration config;
};

TEST_F(ExchangeTest,
       DISABLED_getBalance) // DISABLED_ prefix makes gtest skip this by default
{
  // Mock the configuration to return credentials for testnet
  EXPECT_CALL(config, getEd25519ApiKey())
      .WillOnce(Return("qF07sNUPqW7BHFnWrya6JCowYx7ezmJ0iMGZaNnoBapfbHdMyCaxsYT"
                       "vWJTLafoh")); // testnet cred

  EXPECT_CALL(config, getEd25519Seed())
      .WillOnce(Return(
          "713iwB11x0PYIMHCfk8gjB2Nb4xJAaHN+T1jpfHIF+o=")); // testnet cred

  auto balance = getBalance(config);
  EXPECT_TRUE(balance.getBalance("BTC") >
              0); // assuming the testnet has some BTC
}

TEST_F(ExchangeTest,
       DISABLED_GetSymbolsReturnsValidMap) // DISABLED_ prefix makes gtest skip
                                           // this by default
{
  auto symbols = getSymbols(config);

  // Verify the map contains the expected data
  EXPECT_GT(symbols.size(), 1000);
  EXPECT_TRUE(symbols.find("ETHBTC") != symbols.end());

  // Verify individual symbol details
  const auto &btcEthSymbol = symbols["ETHBTC"];
  EXPECT_EQ(btcEthSymbol.baseAsset, "ETH");
  EXPECT_EQ(btcEthSymbol.quoteAsset, "BTC");
  EXPECT_EQ(btcEthSymbol.baseAssetPrecision, 8);
  EXPECT_EQ(btcEthSymbol.quoteAssetPrecision, 8);
  EXPECT_EQ(btcEthSymbol.minNotional,
            boost::multiprecision::cpp_dec_float_50{"0.0001"});
  EXPECT_EQ(btcEthSymbol.baseAssetIncrement,
            boost::multiprecision::cpp_dec_float_50{"0.0001"});
  EXPECT_EQ(btcEthSymbol.quoteAssetIncrement,
            boost::multiprecision::cpp_dec_float_50{"0.00001"});
}

TEST_F(ExchangeTest,
       DISABLED_GetRelativeValuesReturnsValidMap) // DISABLED_ prefix makes
                                                  // gtest skip this by default
{
  // Create a mock input map of symbols
  std::unordered_map<std::string, Symbol> symbols;

  Symbol btcSymbol;
  btcSymbol.symbol = "BTCUSDT";
  btcSymbol.baseAsset = "BTC";
  btcSymbol.quoteAsset = "USDT";
  symbols[btcSymbol.symbol] = btcSymbol;

  Symbol ethSymbol;
  ethSymbol.symbol = "ETHBTC";
  ethSymbol.baseAsset = "ETH";
  ethSymbol.quoteAsset = "BTC";
  symbols[ethSymbol.symbol] = ethSymbol;

  Symbol xrpSymbol;
  xrpSymbol.symbol = "XRPBTC";
  xrpSymbol.baseAsset = "XRP";
  xrpSymbol.quoteAsset = "BTC";
  symbols[xrpSymbol.symbol] = xrpSymbol;

  // Call the function under test
  auto relativeValues = getRelativeValues(config, symbols);

  // Verify the price of Bitcoin is 1
  EXPECT_EQ(relativeValues["BTC"], 1);

  // Verify all values are greater than 0
  for (const auto &[asset, value] : relativeValues) {
    EXPECT_GT(value, 0);
  }

  // Verify the size of relativeValues equals the number of different assets in
  // the symbols map
  std::unordered_set<std::string> uniqueAssets;
  for (const auto &[symbolName, symbol] : symbols) {
    uniqueAssets.insert(symbol.baseAsset);
    uniqueAssets.insert(symbol.quoteAsset);
  }
  EXPECT_EQ(relativeValues.size(), uniqueAssets.size());

  // Verify the value of assets that cannot be traded with Bitcoin equals the
  // lowest value
  boost::multiprecision::cpp_dec_float_50 lowestValue =
      std::numeric_limits<boost::multiprecision::cpp_dec_float_50>::max();
  for (const auto &[symbolName, symbol] : symbols) {
    if (symbol.quoteAsset == "BTC") {
      lowestValue = std::min(lowestValue, relativeValues[symbol.baseAsset]);
    }
  }

  for (const auto &[asset, value] : relativeValues) {
    bool isRelatedToBTC = false;
    for (const auto &[symbolName, symbol] : symbols) {
      if (asset == "BTC" ||
          (symbol.baseAsset == asset && symbol.quoteAsset == "BTC") ||
          (symbol.quoteAsset == asset && symbol.baseAsset == "BTC")) {
        isRelatedToBTC = true;
        break;
      }
    }
    if (!isRelatedToBTC) {
      EXPECT_EQ(value, lowestValue);
    }
  }
}
