/*
 * ThreadSafeQueueTest.cpp
 * Testing the thread-safe queue.
 */

#include "ThreadSafeQueue.h"
#include <gtest/gtest.h>

TEST(ThreadSafeQueueTest, parallelpushpop) {
  ThreadSafeQueue<int> q;

  // Push and pop in parallel
  std::thread t2([&q]() {
    for (int i = 0; i < 1000; ++i) {
      q.pop();
    }
  });
  std::thread t1([&q]() {
    for (int i = 0; i < 1000; ++i) {
      q.push(i);
    }
  });
  t1.join();
  t2.join();

  // Check if the queue is empty
  ASSERT_TRUE(q.empty());
}
