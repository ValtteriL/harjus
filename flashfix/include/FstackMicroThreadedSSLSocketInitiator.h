#pragma once

#include "FstackMicroThreadedSSLSocketConnection.h"
#include "HostDetailsProvider.h"
#include "Initiator.h"
#include "Session.h"
#include <boost/lockfree/spsc_queue.hpp>
#include <map>
#include <utility>

namespace FIX
{
    /*! \addtogroup user
     *  @{
     */
    /// Fstack MicroThreaded Socket implementation of Initiator.
    class FstackMicroThreadedSSLSocketInitiator : public Initiator
    {
    public:
        FstackMicroThreadedSSLSocketInitiator(Application &, MessageStoreFactory &,
                                              const SessionSettings &, int argc, char *argv[]) EXCEPT(ConfigError);
        FstackMicroThreadedSSLSocketInitiator(Application &, MessageStoreFactory &,
                                              const SessionSettings &, LogFactory &, int argc, char *argv[])
            EXCEPT(ConfigError);

        virtual ~FstackMicroThreadedSSLSocketInitiator();

        void setPassword(const std::string &pwd) { m_password.assign(pwd); }

        void setCertAndKey(X509 *cert, RSA *key)
        {
            m_cert = cert;
            m_key = key;
        }

        int passwordHandleCallback(char *buf, size_t bufsize, int verify);

        static int passwordHandleCB(char *buf, int bufsize, int verify,
                                    void *instance);

        /// Queue a message to be sent to a specific session.
        /// This method is thread-safe and can be called from any thread.
        /// The message will be processed and sent in the F-Stack microthread context.
        /// @param message The FIX message to send
        /// @param sessionID The target session ID
        /// @return true if the message was successfully queued
        bool queueMessage(Message message, const SessionID &sessionID);

    private:
        /// Process any pending outbound messages from the queue.
        /// Must be called from the F-Stack microthread context.
        void processOutboundQueue();
        typedef std::pair<socket_handle, SSL *> SocketKey;
        typedef std::map<SocketKey, thread_id> SocketToThread;
        typedef std::pair<FstackMicroThreadedSSLSocketInitiator *,
                          FstackMicroThreadedSSLSocketConnection *>
            ThreadPair;

        void onConfigure(const SessionSettings &) EXCEPT(ConfigError);
        void onInitialize(const SessionSettings &) EXCEPT(RuntimeError);

        void onStart();
        bool onPoll();
        void onStop();

        void doConnect(const SessionID &s, const Dictionary &d);

        void addThread(SocketKey s, thread_id t);
        void removeThread(SocketKey s);
        void lock() { Locker l(m_mutex); }
        static THREAD_PROC socketThread(void *p);

        HostDetailsProvider m_hostDetailsProvider;
        time_t m_lastConnect;
        int m_reconnectInterval;
        bool m_noDelay;
        int m_sendBufSize;
        int m_rcvBufSize;
        SocketToThread m_threads;
        Mutex m_mutex;
        bool m_sslInit;
        SSL_CTX *m_ctx;
        std::string m_password;
        X509 *m_cert;
        RSA *m_key;
        int m_argc;
        char **m_argv;

        /// Lock-free outbound message queue for cross-thread message submission.
        /// Messages are queued by queueMessage() and processed by processOutboundQueue().
        /// Capacity of 4096 should be sufficient for burst order submission.
        static constexpr std::size_t OutboundQueueCapacity = 4096;
        boost::lockfree::spsc_queue<std::pair<Message, SessionID>,
                                    boost::lockfree::capacity<OutboundQueueCapacity>> m_outboundQueue;
    };
    /*! @} */
} // namespace FIX
