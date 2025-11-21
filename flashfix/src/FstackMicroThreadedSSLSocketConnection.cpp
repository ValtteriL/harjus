#include "FstackMicroThreadedSSLSocketConnection.h"
#include "Session.h"
#include "Utility.h"
#include "UtilitySSL.h"
#include <mt_api.h>
#include <sys/poll.h>

namespace FIX
{
    FstackMicroThreadedSSLSocketConnection::FstackMicroThreadedSSLSocketConnection(
        socket_handle socket, SSL *ssl, Sessions sessions, Log *pLog)
        : m_socket(socket), m_ssl(ssl), m_pLog(pLog), m_sessions(std::move(std::move(sessions))),
          m_pSession(nullptr), m_disconnect(false)
    {
        FD_ZERO(&m_fds);
        FD_SET(m_socket, &m_fds);
    }

    FstackMicroThreadedSSLSocketConnection::FstackMicroThreadedSSLSocketConnection(
        const SessionID &sessionID, socket_handle socket, SSL *ssl,
        std::string address, short port, Log *pLog)
        : m_socket(socket), m_ssl(ssl), m_address(std::move(address)), m_port(port),
          m_pLog(pLog), m_pSession(Session::lookupSession(sessionID)),
          m_disconnect(false)
    {
        FD_ZERO(&m_fds);
        FD_SET(m_socket, &m_fds);
        if (m_pSession)
        {
            m_pSession->setResponder(this);
        }
    }

    FstackMicroThreadedSSLSocketConnection::
        ~FstackMicroThreadedSSLSocketConnection()
    {
        if (m_pSession)
        {
            m_pSession->setResponder(nullptr);
            Session::unregisterSession(m_pSession->getSessionID());
        }
    }

    auto FstackMicroThreadedSSLSocketConnection::send(const std::string &message) -> bool
    {
        int totalSent = 0;

        while (totalSent < (int)message.length())
        {
            errno = 0;
            int errCodeSSL = 0;
            int sent = 0;
            ERR_clear_error();

            // Cannot do concurrent SSL write and read as ssl context has to be
            // protected.
            {
                Locker locker(m_mutex);

                sent = SSL_write(m_ssl, message.c_str() + totalSent,
                                 message.length() - totalSent);
                if (sent <= 0)
                {
                    errCodeSSL = SSL_get_error(m_ssl, sent);
                }
            }

            if (sent <= 0)
            {
                if ((errCodeSSL == SSL_ERROR_WANT_READ) ||
                    (errCodeSSL == SSL_ERROR_WANT_WRITE))
                {
                    errno = EINTR;
                    sent = 0;
                }
                else
                {
                    std::string error = socket_error();

                    m_pSession->getLog()->onEvent("SSL send error <" +
                                                  IntConvertor::convert(errCodeSSL) + "> " +
                                                  error);

                    return false;
                }
            }

            totalSent += sent;
        }

        return true;
    }

    auto FstackMicroThreadedSSLSocketConnection::connect() -> bool
    {
        return socket_connect(getSocket(), m_address.c_str(), m_port) >= 0;
    }

    void FstackMicroThreadedSSLSocketConnection::disconnect()
    {
        m_disconnect = true;
        ssl_socket_close(m_socket, m_ssl);
    }

    auto FstackMicroThreadedSSLSocketConnection::read() -> bool
    {
        struct timeval timeout = {1, 0};
        fd_set readset = m_fds;

        try
        {
            // Wait for input forever
            int result = NS_MICRO_THREAD::mt_wait_events(m_socket, POLLIN, -1);

            if (result > 0) // Something to read
            {
                bool pending = false;

                do
                {
                    pending = false;
                    errno = 0;
                    int size = 0;
                    int errCodeSSL = 0;
                    ERR_clear_error();

                    // Cannot do concurrent SSL write and read as ssl context has to be
                    // protected.
                    {
                        Locker locker(m_mutex);

                        size = SSL_read(m_ssl, m_buffer, sizeof(m_buffer));
                        if (size <= 0)
                        {
                            errCodeSSL = SSL_get_error(m_ssl, size);
                        }
                        else if (SSL_pending(m_ssl) > 0)
                        {
                            pending = true;
                        }
                    }

                    if (size <= 0)
                    {
                        if ((errCodeSSL == SSL_ERROR_WANT_READ) ||
                            (errCodeSSL == SSL_ERROR_WANT_WRITE))
                        {
                            errno = EINTR;
                            size = 0;

                            return true;
                        }
                        else
                        {
                            std::string error = socket_error();

                            if (m_pSession)
                            {
                                m_pSession->getLog()->onEvent("SSL read error <" +
                                                              IntConvertor::convert(errCodeSSL) +
                                                              "> " + error);
                            }
                            else
                            {
                                std::cerr << UtcTimeStampConvertor::convert(UtcTimeStamp::now())
                                          << "SSL read error <"
                                          << IntConvertor::convert(errCodeSSL) << "> " << error
                                          << '\n';
                            }

                            throw SocketRecvFailed(size);
                        }
                    }

                    m_parser.addToStream(m_buffer, size);
                } while (pending);
            }
            else if (result == 0 && m_pSession) // Timeout
            {
                m_pSession->next(UtcTimeStamp::now());
            }
            else if (result < 0) // Error
            {
                throw SocketRecvFailed(result);
            }

            processStream();

            if (m_disconnect)
            {
                return false;
            }

            return true;
        }
        catch (SocketRecvFailed &e)
        {
            if (m_disconnect)
            {
                return false;
            }

            if (m_pSession)
            {
                m_pSession->getLog()->onEvent(e.what());
                m_pSession->disconnect();
            }
            else
            {
                disconnect();
            }

            return false;
        }
    }

    auto FstackMicroThreadedSSLSocketConnection::readMessage(std::string &message) -> bool EXCEPT(SocketRecvFailed)
    {
        try
        {
            return m_parser.readFixMessage(message);
        }
        catch (MessageParseError &)
        {
        }
        return true;
    }

    void FstackMicroThreadedSSLSocketConnection::processStream()
    {
        std::string message;
        while (readMessage(message))
        {
            if (!m_pSession)
            {
                if (!setSession(message))
                {
                    disconnect();
                    continue;
                }
            }
            try
            {
                m_pSession->next(message, UtcTimeStamp::now());
            }
            catch (InvalidMessage &)
            {
                if (!m_pSession->isLoggedOn())
                {
                    disconnect();
                    return;
                }
            }
        }
    }

    auto FstackMicroThreadedSSLSocketConnection::setSession(
        const std::string &message) -> bool
    {
        m_pSession = Session::lookupSession(message, true);
        if (!m_pSession)
        {
            if (m_pLog)
            {
                m_pLog->onEvent("Session not found for incoming message: " + message);
                m_pLog->onIncoming(message);
            }
            return false;
        }

        SessionID sessionID = m_pSession->getSessionID();
        m_pSession = nullptr;

        // see if the session frees up within 5 seconds
        for (int i = 1; i <= 5; i++)
        {
            if (!Session::isSessionRegistered(sessionID))
            {
                m_pSession = Session::registerSession(sessionID);
            }
            if (m_pSession)
            {
                break;
            }
            process_sleep(1);
        }

        if (!m_pSession)
        {
            return false;
        }
        if (m_sessions.find(m_pSession->getSessionID()) == m_sessions.end())
        {
            return false;
        }

        m_pSession->setResponder(this);
        return true;
    }

} // namespace FIX
