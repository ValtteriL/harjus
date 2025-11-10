#include "config.h"
#include <mt_api.h>

#if (HAVE_SSL > 0)

#include "FstackMicroThreadedSSLSocketInitiator.h"
#include "Session.h"
#include "Settings.h"
#include "UtilitySSL.h"
#include <micro_thread.h>
#include <mt_incl.h>

namespace FIX {

int FstackMicroThreadedSSLSocketInitiator::passwordHandleCB(char *buf,
                                                            int bufsize,
                                                            int verify,
                                                            void *instance) {
  return reinterpret_cast<FstackMicroThreadedSSLSocketInitiator *>(instance)
      ->passwordHandleCallback(buf, bufsize, verify);
}

FstackMicroThreadedSSLSocketInitiator::FstackMicroThreadedSSLSocketInitiator(
    Application &application, MessageStoreFactory &factory,
    const SessionSettings &settings) EXCEPT(ConfigError)
    : Initiator(application, factory, settings), m_lastConnect(0),
      m_reconnectInterval(30), m_noDelay(false), m_sendBufSize(0),
      m_rcvBufSize(0), m_sslInit(false), m_ctx(0), m_cert(0), m_key(0) {
  socket_init();
}

FstackMicroThreadedSSLSocketInitiator::FstackMicroThreadedSSLSocketInitiator(
    Application &application, MessageStoreFactory &factory,
    const SessionSettings &settings, LogFactory &logFactory) EXCEPT(ConfigError)
    : Initiator(application, factory, settings, logFactory), m_lastConnect(0),
      m_reconnectInterval(30), m_noDelay(false), m_sendBufSize(0),
      m_rcvBufSize(0), m_sslInit(false), m_ctx(0), m_cert(0), m_key(0) {
  socket_init();
}

FstackMicroThreadedSSLSocketInitiator::
    ~FstackMicroThreadedSSLSocketInitiator() {
  if (m_sslInit) {
    SSL_CTX_free(m_ctx);
    m_ctx = 0;
    ssl_term();
  }

  socket_term();
}

void FstackMicroThreadedSSLSocketInitiator::onConfigure(
    const SessionSettings &s) EXCEPT(ConfigError) {
  const Dictionary &dict = s.get();

  if (dict.has(RECONNECT_INTERVAL)) // ReconnectInterval in [DEFAULT]
  {
    m_reconnectInterval = dict.getInt(RECONNECT_INTERVAL);
  }
  if (dict.has(SOCKET_NODELAY)) {
    m_noDelay = dict.getBool(SOCKET_NODELAY);
  }
  if (dict.has(SOCKET_SEND_BUFFER_SIZE)) {
    m_sendBufSize = dict.getInt(SOCKET_SEND_BUFFER_SIZE);
  }
  if (dict.has(SOCKET_RECEIVE_BUFFER_SIZE)) {
    m_rcvBufSize = dict.getInt(SOCKET_RECEIVE_BUFFER_SIZE);
  }
}

void FstackMicroThreadedSSLSocketInitiator::onInitialize(
    const SessionSettings &s) EXCEPT(RuntimeError) {
  if (m_sslInit) {
    return;
  }

  ssl_init();

  std::string errStr;

  /* set up the application context */
  if ((m_ctx = createSSLContext(false, s, errStr)) == 0) {
    throw RuntimeError(errStr);
  }

  if (m_cert && m_key) {
    if (SSL_CTX_use_certificate(m_ctx, m_cert) < 1) {
      ssl_term();
      throw RuntimeError("Failed to set certificate");
    }

    if (SSL_CTX_use_RSAPrivateKey(m_ctx, m_key) <= 0) {
      ssl_term();
      throw RuntimeError("Failed to set key");
    }
  } else if (!loadSSLCert(
                 m_ctx, false, s, getLog(),
                 FstackMicroThreadedSSLSocketInitiator::passwordHandleCB, this,
                 errStr)) {
    ssl_term();
    throw RuntimeError(errStr);
  }

  int verifyLevel;
  if (!loadCAInfo(m_ctx, false, s, getLog(), errStr, verifyLevel)) {
    ssl_term();
    throw RuntimeError(errStr);
  }

  m_sslInit = true;
}

void FstackMicroThreadedSSLSocketInitiator::onStart() {
  while (!isStopped()) {
    time_t now;
    ::time(&now);

    if ((now - m_lastConnect) >= m_reconnectInterval) {
      Locker l(m_mutex);
      connect();
      m_lastConnect = now;
    }

    process_sleep(1);
  }
}

bool FstackMicroThreadedSSLSocketInitiator::onPoll() { return false; }

void FstackMicroThreadedSSLSocketInitiator::onStop() {
  SocketToThread threads;
  SocketToThread::iterator i;

  {
    Locker l(m_mutex);

    time_t start = 0;
    time_t now = 0;

    ::time(&start);
    while (isLoggedOn()) {
      if (::time(&now) - 5 >= start) {
        break;
      }
    }

    threads = m_threads;
    m_threads.clear();
  }

  for (i = threads.begin(); i != threads.end(); ++i) {
    ssl_socket_close(i->first.first, i->first.second);
  }

  for (i = threads.begin(); i != threads.end(); ++i) {
    thread_join(i->second);
    if (i->first.second != 0) {
      SSL_free(i->first.second);
    }
  }
  threads.clear();
}

void FstackMicroThreadedSSLSocketInitiator::doConnect(const SessionID &s,
                                                      const Dictionary &d) {
  try {
    Session *session = Session::lookupSession(s);
    if (!session->isSessionTime(UtcTimeStamp::now())) {
      return;
    }

    Log *log = session->getLog();

    HostDetails host = m_hostDetailsProvider.getHost(s, d);
    if (d.has(RECONNECT_INTERVAL)) // ReconnectInterval in [SESSION]
    {
      m_reconnectInterval = d.getInt(RECONNECT_INTERVAL);
    }

    socket_handle socket = socket_createConnector();
    if (m_noDelay) {
      socket_setsockopt(socket, TCP_NODELAY);
    }
    if (m_sendBufSize) {
      socket_setsockopt(socket, SO_SNDBUF, m_sendBufSize);
    }
    if (m_rcvBufSize) {
      socket_setsockopt(socket, SO_RCVBUF, m_rcvBufSize);
    }

    setPending(s);
    log->onEvent("Connecting to " + host.address + " on port " +
                 IntConvertor::convert((unsigned short)host.port) +
                 " ReconnectInterval=" +
                 IntConvertor::convert((int)m_reconnectInterval));

    SSL *ssl = SSL_new(m_ctx);
    if (ssl == 0) {
      log->onEvent("Failed to create ssl object");
      return;
    }
    SSL_clear(ssl);
    BIO *sbio = BIO_new_socket(
        socket, BIO_CLOSE); // unfortunately OpenSSL uses int for socket handles
    SSL_set_bio(ssl, sbio, sbio);

    FstackMicroThreadedSSLSocketConnection *pConnection =
        new FstackMicroThreadedSSLSocketConnection(s, socket, ssl, host.address,
                                                   host.port, getLog());

    ThreadPair *pair = new ThreadPair(this, pConnection);

    {
      Locker l(m_mutex);
      thread_id thread;
      if (mt_start_thread((void *)socketThread, pair)) {
        addThread(SocketKey(socket, ssl), thread);
      } else {
        delete pair;
        pConnection->disconnect();
        delete pConnection;
        SSL_free(ssl);
        setDisconnected(s);
      }
    }
  } catch (std::exception &) {
  }
}

void FstackMicroThreadedSSLSocketInitiator::addThread(SocketKey s,
                                                      thread_id t) {
  Locker l(m_mutex);

  m_threads[s] = t;
}

void FstackMicroThreadedSSLSocketInitiator::removeThread(SocketKey s) {
  Locker l(m_mutex);
  SocketToThread::iterator i = m_threads.find(s);

  if (i != m_threads.end()) {
    if (i->first.second != 0) {
      SSL_free(i->first.second);
    }
    m_threads.erase(i);
  }
}

THREAD_PROC FstackMicroThreadedSSLSocketInitiator::socketThread(void *p) {
  ThreadPair *pair = reinterpret_cast<ThreadPair *>(p);

  FstackMicroThreadedSSLSocketInitiator *pInitiator = pair->first;
  FstackMicroThreadedSSLSocketConnection *pConnection = pair->second;
  FIX::SessionID sessionID = pConnection->getSession()->getSessionID();
  FIX::Session *pSession = FIX::Session::lookupSession(sessionID);
  socket_handle socket = pConnection->getSocket();
  delete pair;

  pInitiator->lock();

  if (!pConnection->connect()) {
    pInitiator->getLog()->onEvent("Connection failed");
    pConnection->disconnect();
    SSL *ssl = pConnection->sslObject();
    delete pConnection;
    pInitiator->removeThread(SocketKey(socket, ssl));
    pInitiator->setDisconnected(sessionID);
    return 0;
  }

  // Do the SSL handshake.
  int rc = SSL_connect(pConnection->sslObject());
  if (rc <= 0) {
    int err = SSL_get_error(pConnection->sslObject(), rc);
    pInitiator->getLog()->onEvent("SSL_connect failed with SSL error " +
                                  IntConvertor::convert(err));
    pConnection->disconnect();
    SSL *ssl = pConnection->sslObject();
    delete pConnection;
    pInitiator->removeThread(SocketKey(socket, ssl));
    pInitiator->setDisconnected(sessionID);
    return 0;
  }

  pInitiator->setConnected(sessionID);
  pInitiator->getLog()->onEvent("Connection succeeded");

  pSession->next(UtcTimeStamp::now());

  while (pConnection->read()) {
  }

  SSL *ssl = pConnection->sslObject();
  delete pConnection;
  if (!pInitiator->isStopped()) {
    pInitiator->removeThread(SocketKey(socket, ssl));
  }

  pInitiator->setDisconnected(sessionID);
  return 0;
}

int FstackMicroThreadedSSLSocketInitiator::passwordHandleCallback(
    char *buf, size_t bufsize, int verify) {
  if (m_password.length() > bufsize) {
    return -1;
  }

  std::strcpy(buf, m_password.c_str());
  return m_password.length();
}
} // namespace FIX

#endif
