#pragma once

#include "IApplication.h"
#include <gmock/gmock.h>

class MockApplication : public IApplication {
public:
  MOCK_METHOD(bool, subscribeToSymbols,
              (const std::vector<std::string> &symbols), (override));
  MOCK_METHOD(void, submitOrder,
              (const std::string &id, const std::string &symbol,
               PreciseNumber qty, PreciseNumber price, Position position),
              (override));
};
