#include "StaticTrade.h"

StaticTrade::StaticTrade(const Trade &trade)
    : _symbol(trade.symbol()->symbol), _position(trade.position()),
      _orderQty(trade.orderQty()), _orderPrice(trade.orderPrice()),
      _recvCurrency(trade.recvCurrency()),
      _usedCurrency(trade.usedCurrency()) {};

const std::string StaticTrade::symbol() const { return _symbol; }

enum Position StaticTrade::position() const { return _position; }

boost::multiprecision::cpp_dec_float_50 StaticTrade::orderQty() const {
  return _orderQty;
}

boost::multiprecision::cpp_dec_float_50 StaticTrade::orderPrice() const {
  return _orderPrice;
}

std::string StaticTrade::recvCurrency() const { return _recvCurrency; }

std::string StaticTrade::usedCurrency() const { return _usedCurrency; }

bool StaticTrade::operator==(const StaticTrade &other) const {
  return _symbol == other._symbol && _position == other._position &&
         _orderQty == other._orderQty && _orderPrice == other._orderPrice &&
         _recvCurrency == other._recvCurrency &&
         _usedCurrency == other._usedCurrency;
}