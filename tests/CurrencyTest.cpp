/*
 * CurrencyTest.cpp
 * Testing the Currency class.
 */

#include "Currency.h"
#include <gtest/gtest.h>

TEST(CurrencyTest, ConstructorAndGetOriginalAmount) {
  Currency c1(1.23);
  EXPECT_EQ(c1.getOriginalAmount(), 1);
  Currency c2(0.99);
  EXPECT_EQ(c2.getOriginalAmount(), 0);
  Currency c3(-2.5);
  EXPECT_EQ(c3.getOriginalAmount(), -2);
}

TEST(CurrencyTest, AdditionOperator) {
  Currency c1(1.5);
  Currency c2(2.25);
  Currency sum = c1 + c2;
  EXPECT_EQ(sum.getOriginalAmount(), 3);
}

TEST(CurrencyTest, SubtractionOperator) {
  Currency c1(5.0);
  Currency c2(2.5);
  Currency diff = c1 - c2;
  EXPECT_EQ(diff.getOriginalAmount(), 2);
}

TEST(CurrencyTest, MultiplicationOperator) {
  Currency c1(2.0);
  Currency prod = c1 * 2.5;
  EXPECT_EQ(prod.getOriginalAmount(), 5);
}

TEST(CurrencyTest, EqualityOperator) {
  Currency c1(1.23456789);
  Currency c2(1.23456789);
  Currency c3(1.23456788);
  EXPECT_TRUE(c1 == c2);
  EXPECT_FALSE(c1 == c3);
}

TEST(CurrencyTest, LessThanOperator) {
  Currency c1(1.0);
  Currency c2(2.0);
  EXPECT_TRUE(c1 < c2);
  EXPECT_FALSE(c2 < c1);
}
