#pragma once

#if (HAVE_SSL > 0)

#include "Mutex.h"
#include "Parser.h"
#include "Responder.h"
#include "SessionID.h"
#include "UtilitySSL.h"
#include <map>
#include <set>

namespace FIX {
//class ThreadedSSLSocketAcceptor;
class FstackMicroThreadedSSLSocketInitiator;
class Session;
class Application;
class Log;

/// Encapsulates a socket file descriptor (multi-threaded).
class FstackMicroThreadedSSLSocketConnection : Responder {
public:
  typedef std::set<SessionID> Sessions;

  FstackMicroThreadedSSLSocketConnection(socket_handle s, SSL *ssl, Sessions sessions, Log *pLog);
  FstackMicroThreadedSSLSocketConnection(
      const SessionID &,
      socket_handle s,
      SSL *ssl,
      const std::string &address,
      short port,
      Log *pLog);
  virtual ~FstackMicroThreadedSSLSocketConnection();

  Session *getSession() const { return m_pSession; }
  socket_handle getSocket() const { return m_socket; }
  bool connect();
  void disconnect();
  bool read();
  SSL *sslObject() { return m_ssl; }

private:
  typedef std::pair<socket_handle, SSL *> SocketKey;

  bool readMessage(std::string &msg) EXCEPT(SocketRecvFailed);
  void processStream();
  bool send(const std::string &);
  bool setSession(const std::string &msg);

  socket_handle m_socket;
  SSL *m_ssl;
  char m_buffer[BUFSIZ];

  std::string m_address;
  int m_port;

  Log *m_pLog;
  Parser m_parser;
  Sessions m_sessions;
  Session *m_pSession;
  bool m_disconnect;
  fd_set m_fds;

  Mutex m_mutex;
};
} // namespace FIX

#endif