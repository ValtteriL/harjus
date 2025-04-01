/*
 * PlannedExecutionTest.cpp
 * Testing the PlannedExecution class
 */

#include <gtest/gtest.h>
#include <QJsonDocument>
#include <QString>
#include "PlannedExecution.h"
#include <iostream>

TEST(PlannedExecutionTest, update)
{
  // prices with no special arbitrage opportunities
  // but calculation properties should hold
  long double qty_btc_eth = 10.0;
  long double qty_eth_doge = 5.0;
  long double qty_doge_btc = 3.0;

  long double price_btc_eth = 0.001599;
  long double price_eth_doge = 0.9986;
  long double price_doge_btc = 0.001598;

  TradingSymbol first{QString("BTCETH"), Position::SHORT, QString("BTC"), QString("ETH"), 0.00000001, 8, 0.00000001, 8, 0.0};
  first.setPrice(price_btc_eth);
  first.setMaxQty(qty_btc_eth);

  TradingSymbol second{QString("ETHDOGE"), Position::SHORT, QString("ETH"), QString("DOGE"), 0.00000001, 8, 0.00000001, 8, 0.0};
  second.setPrice(price_eth_doge);
  second.setMaxQty(qty_eth_doge);

  TradingSymbol third{QString("BTCDOGE"), Position::LONG, QString("BTC"), QString("DOGE"), 0.00000001, 8, 0.00000001, 8, 0.0};
  third.setPrice(price_doge_btc);
  third.setMaxQty(qty_doge_btc);

  std::vector<TradingSymbol> trades = {first, second, third};

  // QString symbol, Position position, QString base_asset, QString quote_asset, long double baseAssetIncrement, int baseAssetPrecision, long double quoteAssetIncrement, int quoteAssetPrecision, long double minNotional

  auto relativePrice = 1.0;
  auto commission = 0.001;
  auto plan = PlannedExecution{trades, relativePrice, commission};

  plan.update();

  // properties are set correctly
  ASSERT_EQ(relativePrice, plan.mRelativePrice);
  ASSERT_EQ(commission, plan.mCommission);

  // in each trade, the used balance lte the received in previous trade
  auto received = plan.mTrades.front().usedAmount();
  for (auto trade : plan.mTrades)
  {
    auto used = trade.usedAmount();

    std::cerr << "used: " << used << " received: " << received << std::endl;

    ASSERT_GE(received, used);
    received = trade.receiveivedAmount();
  }
}
