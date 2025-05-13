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

std::size_t StaticTrade::hash() const {
  return std::hash<std::string>()(symbol()) ^ std::hash<Position>()(position());
}