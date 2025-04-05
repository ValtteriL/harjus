#include "HttpClient.h"
#include "RootCertificates.h"

#include <boost/beast/core.hpp>
#include <boost/beast/http.hpp>
#include <boost/beast/version.hpp>
#include <boost/asio/connect.hpp>
#include <boost/asio/ip/tcp.hpp>
#include <boost/asio/ssl.hpp>
#include <cstdlib>
#include <iostream>

#include <boost/url/url.hpp>
#include <boost/url/parse.hpp>

namespace beast = boost::beast; // from <boost/beast.hpp>
namespace http = beast::http;   // from <boost/beast/http.hpp>
namespace net = boost::asio;    // from <boost/asio.hpp>
namespace ssl = net::ssl;       // from <boost/asio/ssl.hpp>
using tcp = net::ip::tcp;       // from <boost/asio/ip/tcp.hpp>

namespace urls = boost::urls;

std::string get(std::string_view uri)
{
  // parse host and port from the URI
  urls::url parsed_uri = urls::parse_uri(uri).value();
  std::string host = parsed_uri.host();
  std::string port = parsed_uri.port();
  std::string target = parsed_uri.path();
  std::string version = "HTTP/1.1";

  // The io_context is required for all I/O
  net::io_context ioc;

  // The SSL context is required, and holds certificates
  ssl::context ctx(ssl::context::tlsv12_client);

  // This holds the root certificate used for verification
  load_root_certificates(ctx);

  // disable verification of the server certificate
  ctx.set_verify_mode(ssl::verify_peer);

  // These objects perform our I/O
  tcp::resolver resolver(ioc);
  ssl::stream<beast::tcp_stream> stream(ioc, ctx);

  // Set SNI Hostname (many hosts need this to handshake successfully)
  if (!SSL_set_tlsext_host_name(stream.native_handle(), &host))
  {
    beast::error_code ec{static_cast<int>(::ERR_get_error()), net::error::get_ssl_category()};
    throw beast::system_error{ec};
  }

  // Look up the domain name
  auto const results = resolver.resolve(host, port);

  // Make the connection on the IP address we get from a lookup
  beast::get_lowest_layer(stream).connect(results);

  // Perform the SSL handshake
  stream.handshake(ssl::stream_base::client);

  // Set up an HTTP GET request message
  http::request<http::string_body> req{http::verb::get, target.c_str(), 11};
  req.set(http::field::host, host);
  req.set(http::field::user_agent, "Harjus");

  // Send the HTTP request to the remote host
  http::write(stream, req);

  // This buffer is used for reading and must be persisted
  beast::flat_buffer buffer;

  // Declare a container to hold the response
  http::response<http::dynamic_body> res;

  // Receive the HTTP response
  http::read(stream, buffer, res);

  // Write the message to standard out
  std::cout << res << std::endl;

  // Gracefully close the stream
  beast::error_code ec;
  stream.shutdown(ec);

  if (ec != net::ssl::error::stream_truncated)
    throw beast::system_error{ec};

  // return the response body
  return boost::beast::buffers_to_string(res.body().data());
}