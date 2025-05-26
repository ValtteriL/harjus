#pragma once

#include "PreciseNumber.h"
#include <string>

class IConfiguration {
public:
  virtual std::string getBinanceRESTApiUri() const = 0;
  virtual std::string getBinanceFIXApiHostnameOrderEntry() const = 0;
  virtual std::string getBinanceFIXApiHostnameMarketData() const = 0;
  virtual std::string getBinanceFIXApiPortOrderEntry() const = 0;
  virtual std::string getBinanceFIXApiPortMarketData() const = 0;
  virtual std::string getEd25519Seed() const = 0; // private key seed in base64
  virtual std::string
  getEd25519ApiKey() const = 0; // public key in PEM without header and trailer
  virtual int getMaxTradingPathLength() const = 0;
  virtual std::vector<std::string> getBlacklistedStartAssets() const = 0;
  virtual std::vector<std::string> getBlacklistedSymbols() const = 0;
  virtual PreciseNumber getCommission() const = 0;
  virtual int getLogLevel() const = 0;
  virtual std::string getFixFileStorePath() const = 0;
};
