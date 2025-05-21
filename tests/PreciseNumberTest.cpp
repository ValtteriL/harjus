/*
 * PreciseNumberTest.cpp
 * Testing the PreciseNumber class.
 */

#include "PreciseNumber.h"
#include <gtest/gtest.h>

TEST(PreciseNumberTest, ConstructorAndtoDouble) {
  PreciseNumber c1(1.23);
  EXPECT_EQ(c1.toDouble(), 1.23);
  PreciseNumber c2(0.99);
  EXPECT_EQ(c2.toDouble(), 0.99);
  PreciseNumber c3(-2.5);
  EXPECT_EQ(c3.toDouble(), -2.5);
}

TEST(PreciseNumberTest, AdditionOperator) {
  PreciseNumber c1(1.5);
  PreciseNumber c2(2.25);
  PreciseNumber sum = c1 + c2;
  EXPECT_EQ(sum.toDouble(), 3.75);
}

TEST(PreciseNumberTest, SubtractionOperator) {
  PreciseNumber c1(5.0);
  PreciseNumber c2(2.5);
  PreciseNumber diff = c1 - c2;
  EXPECT_EQ(diff.toDouble(), 2.5);
}

TEST(PreciseNumberTest, SubtractAssignOperator) {
  PreciseNumber c1(5.0);
  PreciseNumber c2(2.5);
  c1 -= c2;
  EXPECT_DOUBLE_EQ(c1.toDouble(), 2.5);
}

TEST(PreciseNumberTest, MultiplicationOperator) {
  PreciseNumber c1(2.0);
  PreciseNumber c2(2.5);
  PreciseNumber prod = c1 * c2;
  EXPECT_EQ(prod.toDouble(), 5.0);
}

TEST(PreciseNumberTest, DivisionOperator) {
  PreciseNumber c1(5.0);
  PreciseNumber c2(2.0);
  PreciseNumber quotient = c1 / c2;
  EXPECT_DOUBLE_EQ(quotient.toDouble(), 2.5);
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

TEST(PreciseNumberTest, FmodOperator) {
  PreciseNumber c1(5.75);
  PreciseNumber c2(2.5);
  PreciseNumber rem = PreciseNumber::fmod(c1, c2);
  EXPECT_DOUBLE_EQ(rem.toDouble(), 0.75);
  PreciseNumber c3(-5.75);
  PreciseNumber rem2 = PreciseNumber::fmod(c3, c2);
  EXPECT_DOUBLE_EQ(rem2.toDouble(), -0.75);
}

TEST(PreciseNumberTest, MinValue) {
  PreciseNumber c1(1.23);
  PreciseNumber c2(0.99);
  PreciseNumber minVal = PreciseNumber::min(c1, c2);
  EXPECT_EQ(minVal, c2);
  PreciseNumber c3(-2.5);
  minVal = PreciseNumber::min(c1, c3);
  EXPECT_EQ(minVal, c3);
}
