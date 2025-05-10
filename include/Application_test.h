#pragma once

#include "IApplication.h"
#include <gmock/gmock.h>

class MockApplication : public IApplication {
public:
  MOCK_METHOD(bool, subscribeToSymbols,
              (const std::vector<std::string> &symbols), (override));
  MOCK_METHOD(void, submitOrder,
              (std::string id, const Symbol *symbol,
               boost::multiprecision::cpp_dec_float_50 qty,
               boost::multiprecision::cpp_dec_float_50 price,
               Position position),
              (override));
};
