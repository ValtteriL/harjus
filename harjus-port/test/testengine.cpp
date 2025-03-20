/*
 * testengine.cpp
 * Testing the engine class
 */

#include <QTest>

class TestEngine : public QObject
{
  Q_OBJECT
private slots:
  void fromJson();
};

void TestEngine::fromJson()
{
  QCOMPARE(1, 1);
}

QTEST_MAIN(TestEngine)
#include "testengine.moc"