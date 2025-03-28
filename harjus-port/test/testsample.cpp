/*
 * testsample.cpp
 * Testing the testing framework
 */

#include <QTest>

class TestSample : public QObject
{
  Q_OBJECT
private slots:
  void test1();
  void test2();
};

void TestSample::test1()
{
  QCOMPARE(1, 1);
}

void TestSample::test2()
{
  QVERIFY(1 == 1);
}

QTEST_MAIN(TestSample)
#include "testsample.moc"