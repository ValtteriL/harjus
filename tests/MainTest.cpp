/*
 * MainTest.cpp
 * Testing the testing framework
 */

#include <gtest/gtest.h>

TEST(MainTest, oneEqualToOne)
{
  EXPECT_EQ(1, 1);
}

TEST(MainTest, oneDoesNotEqualToTwo)
{
  ASSERT_NE(1, 2);
}

TEST(MainTest, OneIsOne)
{
  EXPECT_TRUE(1 == 1);
}
