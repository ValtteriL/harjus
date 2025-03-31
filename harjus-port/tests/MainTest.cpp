/*
 * MainTest.cpp
 * Testing the testing framework
 */

#include <QTest>

class MainTest : public QObject
{
  Q_OBJECT
private slots:
  void test1();
  void test2();
};

void MainTest::test1()
{
  QCOMPARE(1, 1);
}

void MainTest::test2()
{
  QVERIFY(1 == 1);
}

QTEST_MAIN(MainTest)
#include "MainTest.moc"