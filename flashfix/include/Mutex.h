#ifndef FIX_MUTEX_H
#define FIX_MUTEX_H

#include "Utility.h"
#include <atomic>
#include <mt_api.h>
#include <thread>

namespace FIX
{
    /// Portable implementation of a mutex.
    class Mutex
    {
    public:
        Mutex() : m_recursion(0), m_owner(nullptr)
        {
        }

        ~Mutex()
        {
        }

        void lock()
        {
            void *self = get_self_id();

            // Check for recursion
            if (m_owner.load(std::memory_order_relaxed) == self)
            {
                m_recursion++;
                return;
            }

            // Spin/Yield loop
            while (true)
            {
                void *expected = nullptr;
                if (m_owner.compare_exchange_weak(expected, self, std::memory_order_acquire))
                {
                    // Acquired
                    m_recursion = 1;
                    return;
                }

                // Failed to acquire
                if (is_microthread())
                {
                    NS_MICRO_THREAD::mt_sleep(1); // Yield
                }
                else
                {
                    std::this_thread::yield(); // Yield Pthread
                }
            }
        }

        void unlock()
        {
            m_recursion--;
            if (m_recursion == 0)
            {
                m_owner.store(nullptr, std::memory_order_release);
            }
        }

    private:
        int m_recursion;
        std::atomic<void *> m_owner;

        bool is_microthread() const
        {
            return NS_MICRO_THREAD::mt_active_thread() != nullptr;
        }

        void *get_self_id() const
        {
            void *mt = NS_MICRO_THREAD::mt_active_thread();
            if (mt)
                return mt;

            static thread_local char marker;
            return (void *)&marker;
        }
    };

    /// Locks/Unlocks a mutex using RAII.
    class Locker
    {
    public:
        Locker(Mutex &mutex)
            : m_mutex(mutex)
        {
            m_mutex.lock();
        }

        ~Locker() { m_mutex.unlock(); }

    private:
        Mutex &m_mutex;
    };

    /// Does the opposite of the Locker to ensure mutex ends up in a locked state.
    class ReverseLocker
    {
    public:
        ReverseLocker(Mutex &mutex)
            : m_mutex(mutex)
        {
            m_mutex.unlock();
        }

        ~ReverseLocker() { m_mutex.lock(); }

    private:
        Mutex &m_mutex;
    };
} // namespace FIX

#endif
