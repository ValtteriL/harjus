/*
 * ThreadSafeQueueTest.cpp
 * Testing the thread-safe queue.
 */

#include "ThreadSafeQueue.h"
#include <gtest/gtest.h>
#include <semaphore>

TEST(ThreadSafeQueueTest, parallelpushpop) {
  std::binary_semaphore sem(0);
  ThreadSafeQueue<int> q(sem);

  // Push and pop in parallel
  std::thread t2([&q]() {
    for (int i = 0; i < 1000; ++i) {
      // Wait for the semaphore to be released
      q.getSemaphore().acquire();
      int value;
      q.try_pop(value);
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
