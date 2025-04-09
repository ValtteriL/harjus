/*
 * ExchangeTest.cpp
 * Testing the Exchange class.
 */

#include <gtest/gtest.h>
#include "Exchange.h"
#include "Configuration_test.h"

using ::testing::Return;

/**
 * Test fixture.
 */

class ExchangeTest : public testing::Test
{
protected:
  ExchangeTest()
  {
    EXPECT_CALL(config, getBinanceRESTApiUri())
        .WillOnce(Return("https://testnet.binance.vision"));
  }

  MockConfiguration config;
};

TEST_F(ExchangeTest, DISABLED_getBalance) // DISABLED_ prefix makes gtest skip this by default
{
  // Mock the configuration to return credentials for testnet
  EXPECT_CALL(config, getEd25519ApiKey())
      .WillOnce(Return("qF07sNUPqW7BHFnWrya6JCowYx7ezmJ0iMGZaNnoBapfbHdMyCaxsYTvWJTLafoh")); // testnet cred

  EXPECT_CALL(config, getEd25519Seed())
      .WillOnce(Return("713iwB11x0PYIMHCfk8gjB2Nb4xJAaHN+T1jpfHIF+o=")); // testnet cred

  auto balance = getBalance(config);
  EXPECT_TRUE(balance.getBalance("BTC") > 0); // assuming the testnet has some BTC
}

TEST_F(ExchangeTest, GetSymbolsReturnsValidMap)
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
  EXPECT_EQ(btcEthSymbol.minNotional, boost::multiprecision::cpp_dec_float_50{"0.0001"});
  EXPECT_EQ(btcEthSymbol.baseAssetIncrement, boost::multiprecision::cpp_dec_float_50{"0.0001"});
  EXPECT_EQ(btcEthSymbol.quoteAssetIncrement, boost::multiprecision::cpp_dec_float_50{"0.00001"});
}
