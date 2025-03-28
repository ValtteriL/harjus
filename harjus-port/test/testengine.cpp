/*
 * testengine.cpp
 * Testing the engine class
 */

#include <QTest>
#include <QJsonDocument>
#include "../engine.h"

class TestEngine : public QObject
{
  Q_OBJECT
private slots:
  void fromJson_update();
};

void TestEngine::fromJson_update()
{
  QString symbol = "ETHBTC";
  QString jsonStr = R"(
  {
    "commission": "0.001",
    "relative_asset_values": {
      "BTC": "1.0",
      "ETH": "0.5"
    },
    "trading_paths": [
    [
      {
        "base_asset": "ETH",
        "base_asset_increment": "0.00000001",
        "base_asset_precision": 8,
        "min_notional": "1.0",
        "position": "long",
        "price": "0",
        "qty": "0",
        "quote_asset": "BTC",
        "quote_asset_increment": "0.00000001",
        "quote_asset_precision": 8,
        "symbol": "%1"
      }
    ],
    [
      {
        "base_asset": "ETH",
        "base_asset_increment": "0.00000001",
        "base_asset_precision": 8,
        "min_notional": "1.0",
        "position": "long",
        "price": "0",
        "qty": "0",
        "quote_asset": "BTC",
        "quote_asset_increment": "0.00000001",
        "quote_asset_precision": 8,
        "symbol": "BTCUSDT"
      },
      {
        "base_asset": "DOGE",
        "base_asset_increment": "0.00000001",
        "base_asset_precision": 8,
        "min_notional": "1.0",
        "position": "long",
        "price": "0",
        "qty": "0",
        "quote_asset": "SOL",
        "quote_asset_increment": "0.00000001",
        "quote_asset_precision": 8,
        "symbol": "%1"
      }
    ]
    ]
  }
  )";

  QByteArray json = jsonStr.arg(symbol).toUtf8();
  auto engine = Engine::fromJson(QJsonDocument::fromJson(json).object());

  QString priceUpdateStr = R"(
    {
      "s": "%1",
      "b": "0.00000001",
      "B": "1.0",
      "a": "0.00000001",
      "A": "1.0"
    }
  )";

  QByteArray priceUpdateJson = priceUpdateStr.arg(symbol).toUtf8();

  auto opportunities = engine.priceUpdate(QJsonDocument::fromJson(priceUpdateJson).object());

  // only single opportunity with positive profit should be found
  // as default profit is 0 and no update has been implemented
  QCOMPARE(opportunities.size(), 1);
  QVERIFY(opportunities.at(0).totalProfit() > 0);
}

QTEST_MAIN(TestEngine)
#include "testengine.moc"
