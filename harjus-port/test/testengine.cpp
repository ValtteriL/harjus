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
  void fromJson();
};

void TestEngine::fromJson()
{
  QByteArray json = R"(
  {
    "commission": 0.001,
    "relative_asset_values": {
      "BTC": 1.0,
      "ETH": 0.5
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
        "symbol": "ETHBTC"
      }
    ]
    ]
  }
  )";
  Engine engine = Engine::fromJson(QJsonDocument::fromJson(json).object());

  QCOMPARE(1, 1);
}

QTEST_MAIN(TestEngine)
#include "testengine.moc"