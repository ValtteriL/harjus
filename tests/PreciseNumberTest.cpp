/*
 * PreciseNumberTest.cpp
 * Testing the PreciseNumber class.
 */

#include "PreciseNumber.h"
#include <gtest/gtest.h>
#include <sstream>

TEST(PreciseNumberTest, ConstructorAndtoString) {
  PreciseNumber c1{"1.23"};
  EXPECT_EQ(c1.toString(), "1.23");
  PreciseNumber c2{"0.99"};
  EXPECT_EQ(c2.toString(), "0.99");
  PreciseNumber c3{"-2.5"};
  EXPECT_EQ(c3.toString(), "-2.5");
}

TEST(PreciseNumberTest, AdditionOperator) {
  PreciseNumber c1{"1.5"};
  PreciseNumber c2{"2.25"};
  PreciseNumber sum = c1 + c2;
  EXPECT_EQ(sum.toString(), "3.75");
}

TEST(PreciseNumberTest, SubtractionOperator) {
  PreciseNumber c1{"5.0"};
  PreciseNumber c2{"2.5"};
  PreciseNumber diff = c1 - c2;
  EXPECT_EQ(diff.toString(), "2.5");
}

TEST(PreciseNumberTest, SubtractAssignOperator) {
  PreciseNumber c1{"5.0"};
  PreciseNumber c2{"2.5"};
  c1 -= c2;
  EXPECT_EQ(c1.toString(), "2.5");
}

TEST(PreciseNumberTest, MultiplicationOperator) {
  PreciseNumber c1{"2.0"};
  PreciseNumber c2{"2.5"};
  PreciseNumber prod = c1 * c2;
  EXPECT_EQ(prod.toString(), "5");
}

TEST(PreciseNumberTest, MultiplyAssignOperator) {
  PreciseNumber c1{"2.0"};
  PreciseNumber c2{"2.5"};
  c1 *= c2;
  EXPECT_EQ(c1.toString(), "5");
}

TEST(PreciseNumberTest, DivisionOperator) {
  PreciseNumber c1{"5.0"};
  PreciseNumber c2{"2.0"};
  PreciseNumber quotient = c1 / c2;
  EXPECT_EQ(quotient.toString(), "2.5");
}

TEST(PreciseNumberTest, DivideAssignOperator) {
  PreciseNumber c1{"5.0"};
  PreciseNumber c2{"2.0"};
  c1 /= c2;
  EXPECT_EQ(c1.toString(), "2.5");
}

TEST(PreciseNumberTest, EqualityOperator) {
  PreciseNumber c1{"1.234567890"};
  PreciseNumber c2{"1.234567890"};
  PreciseNumber c3{"1.234567881"};
  EXPECT_TRUE(c1 == c2);
  EXPECT_FALSE(c1 == c3);
}

TEST(PreciseNumberTest, LessThanOperator) {
  PreciseNumber c1{"1.0"};
  PreciseNumber c2{"2.0"};
  EXPECT_TRUE(c1 < c2);
  EXPECT_FALSE(c2 < c1);
}

TEST(PreciseNumberTest, GreaterThanOperator) {
  PreciseNumber c1{"3.0"};
  PreciseNumber c2{"2.0"};
  EXPECT_TRUE(c1 > c2);
  EXPECT_FALSE(c2 > c1);
}

TEST(PreciseNumberTest, GreaterThanOrEqualOperator) {
  PreciseNumber c1{"3.0"};
  PreciseNumber c2{"2.0"};
  PreciseNumber c3{"3.0"};
  EXPECT_TRUE(c1 >= c2);
  EXPECT_TRUE(c1 >= c3);
  EXPECT_FALSE(c2 >= c1);
}

TEST(PreciseNumberTest, FmodOperator) {
  PreciseNumber c1{"5.75"};
  PreciseNumber c2{"2.5"};
  PreciseNumber rem = PreciseNumber::fmod(c1, c2);
  EXPECT_EQ(rem.toString(), "0.75");
  PreciseNumber c3{"-5.75"};
  PreciseNumber rem2 = PreciseNumber::fmod(c3, c2);
  EXPECT_EQ(rem2.toString(), "-0.75");
}

TEST(PreciseNumberTest, MinValue) {
  PreciseNumber c1{"1.23"};
  PreciseNumber c2{"0.99"};
  PreciseNumber minVal = PreciseNumber::min(c1, c2);
  EXPECT_EQ(minVal, c2);
  PreciseNumber c3{"-2.5"};
  minVal = PreciseNumber::min(c1, c3);
  EXPECT_EQ(minVal, c3);
}

TEST(PreciseNumberTest, AddAssignOperator) {
  PreciseNumber c1{"1.5"};
  PreciseNumber c2{"2.25"};
  c1 += c2;
  EXPECT_EQ(c1.toString(), "3.75");
}

TEST(PreciseNumberTest, OutputStreamOperator) {
  PreciseNumber c{"1.2345"};
  std::ostringstream oss;
  oss << c;
  EXPECT_EQ(oss.str(), "1.2345");
  PreciseNumber c2{"-0.5678"};
  std::ostringstream oss2;
  oss2 << c2;
  EXPECT_EQ(oss2.str(), "-0.5678");
  // Test very small number is printed in decimal, not exponential form
  PreciseNumber c3{"1.48e-6"};
  std::ostringstream oss3;
  oss3 << c3;
  EXPECT_EQ(oss3.str(), "0.00000148");
  // Test number without decimals is printed without decimal point or trailing
  // zeros
  PreciseNumber c4{"5.000"};
  std::ostringstream oss4;
  oss4 << c4;
  EXPECT_EQ(oss4.str(), "5");
}
