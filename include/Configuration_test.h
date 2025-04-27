#pragma once

#include "IConfiguration.h"
#include <gmock/gmock.h>

class MockConfiguration : public IConfiguration {
public:
  MOCK_METHOD(std::string, getBinanceRESTApiUri, (), (const, override));
  MOCK_METHOD(std::string, getBinanceFIXApiHostnameOrderEntry, (),
              (const, override));
  MOCK_METHOD(std::string, getBinanceFIXApiHostnameMarketData, (),
              (const, override));
  MOCK_METHOD(std::string, getBinanceFIXApiPortOrderEntry, (),
              (const, override));
  MOCK_METHOD(std::string, getBinanceFIXApiPortMarketData, (),
              (const, override));
  MOCK_METHOD(std::string, getEd25519Seed, (), (const, override));
  MOCK_METHOD(std::string, getEd25519ApiKey, (), (const, override));
  MOCK_METHOD(int, getMaxTradingPathLength, (), (const, override));
  MOCK_METHOD(std::vector<std::string>, getStartSymbols, (), (const, override));
  MOCK_METHOD(std::vector<std::string>, getBlacklistedStartSymbols, (),
              (const, override));
  MOCK_METHOD(boost::multiprecision::cpp_dec_float_50, getCommission, (),
              (const, override));
  MOCK_METHOD(int, getLogLevel, (), (const, override));
  MOCK_METHOD(std::string, getFixFileStorePath, (), (const, override));
};
