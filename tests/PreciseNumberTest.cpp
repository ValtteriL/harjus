/*
 * PreciseNumberTest.cpp
 * Testing the PreciseNumber class.
 */

#include "PreciseNumber.h"
#include <gtest/gtest.h>

TEST(PreciseNumberTest, ConstructorAndGetOriginalAmount) {
  PreciseNumber c1(1.23);
  EXPECT_EQ(c1.getOriginalAmount(), 1);
  PreciseNumber c2(0.99);
  EXPECT_EQ(c2.getOriginalAmount(), 0);
  PreciseNumber c3(-2.5);
  EXPECT_EQ(c3.getOriginalAmount(), -2);
}

TEST(PreciseNumberTest, AdditionOperator) {
  PreciseNumber c1(1.5);
  PreciseNumber c2(2.25);
  PreciseNumber sum = c1 + c2;
  EXPECT_EQ(sum.getOriginalAmount(), 3);
}

TEST(PreciseNumberTest, SubtractionOperator) {
  PreciseNumber c1(5.0);
  PreciseNumber c2(2.5);
  PreciseNumber diff = c1 - c2;
  EXPECT_EQ(diff.getOriginalAmount(), 2);
}

TEST(PreciseNumberTest, MultiplicationOperator) {
  PreciseNumber c1(2.0);
  PreciseNumber prod = c1 * 2.5;
  EXPECT_EQ(prod.getOriginalAmount(), 5);
}

TEST(PreciseNumberTest, EqualityOperator) {
  PreciseNumber c1(1.23456789);
  PreciseNumber c2(1.23456789);
  PreciseNumber c3(1.23456788);
  EXPECT_TRUE(c1 == c2);
  EXPECT_FALSE(c1 == c3);
}

TEST(PreciseNumberTest, LessThanOperator) {
  PreciseNumber c1(1.0);
  PreciseNumber c2(2.0);
  EXPECT_TRUE(c1 < c2);
  EXPECT_FALSE(c2 < c1);
}
