#pragma once

/**
 * a thread-safe queue implementation
 */
#include <condition_variable>
#include <deque>
#include <mutex>
template <typename T> class ThreadSafeQueue {

private:
  std::deque<T> deque;
  std::mutex mutex;
  std::condition_variable condNotEmpty;

public:
  /*
   * @brief Push an element to the queue
   * @param value The value to push
   */
  void push(const T &value) {
    std::unique_lock<std::mutex> lock(mutex);
    deque.push_back(value);
    lock.unlock();
    // Notify one waiting thread that an item has been added
    condNotEmpty.notify_one();
  }

  /*
   * @brief Pop an element from the queue
   * @return The popped value
   */
  T pop() {
    std::unique_lock<std::mutex> lock(mutex);
    condNotEmpty.wait(lock, [this] { return !deque.empty(); });
    T value = deque.front();
    deque.pop_front();
    return value;
  }

  /*
   * @brief Check if the queue is empty
   * @return True if the queue is empty, false otherwise
   */
  bool empty() {
    std::lock_guard<std::mutex> lock(mutex);
    return deque.empty();
  }
};