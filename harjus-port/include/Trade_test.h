#pragma once

#include "ITrade.h"
#include <gmock/gmock.h>

class MockTrade : public ITrade
{
public:
  MOCK_METHOD(Position, getPosition, (), (const, override));
  MOCK_METHOD(boost::multiprecision::cpp_dec_float_50, getOrderQty, (), (const, override));
  MOCK_METHOD(boost::multiprecision::cpp_dec_float_50, getOrderPrice, (), (const, override));
  MOCK_METHOD(const std::string &, getSymbol, (), (const, override));
  MOCK_METHOD(void, setBudget, (boost::multiprecision::cpp_dec_float_50 budget), (override));
  MOCK_METHOD(boost::multiprecision::cpp_dec_float_50, getRecvQty, (), (const, override));
  MOCK_METHOD(boost::multiprecision::cpp_dec_float_50, getUsedQty, (), (const, override));
  MOCK_METHOD(std::string_view, getRecvCurrency, (), (const, override));
  MOCK_METHOD(std::string_view, getUsedCurrency, (), (const, override));
};
