#pragma once

#include "IConfiguration.h"
#include <gmock/gmock.h>

class MockConfiguration : public IConfiguration
{
public:
  MOCK_METHOD(std::string, getBinanceRESTApiUri, (), (const, override));
  MOCK_METHOD(std::string, getBinanceFIXApiHostname, (), (const, override));
  MOCK_METHOD(std::string, getBinanceFIXApiPort, (), (const, override));
  MOCK_METHOD(std::string, getEd25519Seed, (), (const, override));
  MOCK_METHOD(std::string, getEd25519ApiKey, (), (const, override));
  MOCK_METHOD(int, getMaxTradingPathLength, (), (const, override));
  MOCK_METHOD(std::vector<std::string>, getStartSymbols, (), (const, override));
  MOCK_METHOD(std::vector<std::string>, getBlacklistedStartSymbols, (), (const, override));
  MOCK_METHOD(boost::multiprecision::cpp_dec_float_50, getCommission, (), (const, override));
};
