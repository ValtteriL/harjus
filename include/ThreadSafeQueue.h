#pragma once

/**
 * a thread-safe queue implementation
 */
#include <deque>
#include <mutex>
#include <semaphore>
template <typename T> class ThreadSafeQueue {

private:
  std::deque<T> _deque;
  mutable std::mutex _mutex;
  std::binary_semaphore &_semaphore;

public:
  /*
   * @brief Constructor
   * @param semaphore The semaphore to use for synchronization
   */
  ThreadSafeQueue(std::binary_semaphore &semaphore) : _semaphore(semaphore) {}
  /*
   * @brief Push an element to the queue
   * @param value The value to push
   */
  void push(const T &value) {
    std::lock_guard<std::mutex> lock(_mutex);
    _deque.push_back(value);
    _semaphore.release();
  }

  /*
   * @brief Pop an element from the queue
   * @return The popped value
   */
  bool try_pop(T &item) {
    std::lock_guard<std::mutex> lock(_mutex);
    if (_deque.empty()) {
      return false;
    }
    item = std::move(_deque.front());
    _deque.pop_front();
    return true;
  }

  /*
   * @brief Check if the queue is empty
   * @return True if the queue is empty, false otherwise
   */
  bool empty() const {
    std::lock_guard<std::mutex> lock(_mutex);
    return _deque.empty();
  }

  /*
   * @brief Get the semaphore
   * @return The semaphore
   */
  std::binary_semaphore &getSemaphore() const { return _semaphore; }
};