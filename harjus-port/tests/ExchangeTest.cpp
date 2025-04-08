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

    EXPECT_CALL(config, getEd25519ApiKey())
        .WillOnce(Return("qF07sNUPqW7BHFnWrya6JCowYx7ezmJ0iMGZaNnoBapfbHdMyCaxsYTvWJTLafoh")); // testnet cred

    EXPECT_CALL(config, getEd25519Seed())
        .WillOnce(Return("713iwB11x0PYIMHCfk8gjB2Nb4xJAaHN+T1jpfHIF+o=")); // testnet cred
  }

  MockConfiguration config;
};

TEST_F(ExchangeTest, DISABLED_getBalance) // DISABLED_ prefix makes gtest skip this by default
{
  auto balance = getBalance(config);
  EXPECT_TRUE(balance.getBalance("BTC") > 0); // assuming the testnet has some BTC
}
