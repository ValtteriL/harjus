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
      {
        "from": "BTC",
        "to": "ETH",
        "fee": 0.002
      }
    ]
  }
  )";
  Engine engine = Engine::fromJson(QJsonDocument::fromJson(json).object());

  QCOMPARE(1, 1);
}

QTEST_MAIN(TestEngine)
#include "testengine.moc"