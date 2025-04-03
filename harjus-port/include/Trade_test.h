#pragma once

#include "ITrade.h"
#include <gmock/gmock.h>

class MockTrade : public ITrade
{
public:
  MOCK_METHOD(Position, getPosition, (), (const, override));
  MOCK_METHOD(long double, getOrderQty, (), (const, override));
  MOCK_METHOD(long double, getOrderPrice, (), (const, override));
  MOCK_METHOD(const std::string &, getSymbol, (), (const, override));
  MOCK_METHOD(void, setBudget, (long double budget), (override));
  MOCK_METHOD(long double, getRecvQty, (), (const, override));
  MOCK_METHOD(long double, getUsedQty, (), (const, override));
  MOCK_METHOD(std::string_view, getRecvCurrency, (), (const, override));
  MOCK_METHOD(std::string_view, getUsedCurrency, (), (const, override));
};
