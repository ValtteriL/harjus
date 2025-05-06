/*
 * TraderTest.cpp
 * Testing the Trader.
 */

#include <boost/lockfree/queue.hpp>
#include <gmock/gmock.h>
#include <gtest/gtest.h>

/**
 * Test fixture for Trader.
 */

class TraderTest : public testing::Test {
protected:
  TraderTest() {};
};

TEST_F(TraderTest, figuresomethingout) { ASSERT_TRUE(false); }
