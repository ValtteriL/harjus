#pragma once

#include <boost/multiprecision/cpp_dec_float.hpp>
#include <string>

class IConfiguration {
public:
  virtual std::string getBinanceRESTApiUri() const = 0;
  virtual std::string getBinanceFIXApiHostname() const = 0;
  virtual std::string getBinanceFIXApiPort() const = 0;
  virtual std::string getEd25519Seed() const = 0; // private key seed in base64
  virtual std::string
  getEd25519ApiKey() const = 0; // public key in PEM without header and trailer
  virtual int getMaxTradingPathLength() const = 0;
  virtual std::vector<std::string> getStartSymbols() const = 0;
  virtual std::vector<std::string> getBlacklistedStartSymbols() const = 0;
  virtual boost::multiprecision::cpp_dec_float_50 getCommission() const = 0;
  virtual int getLogLevel() const = 0;
  virtual std::string getFixFileDir() const = 0;
};
