#include "StaticTrade.h"

StaticTrade::StaticTrade(const Trade &trade)
    : _symbol(trade.symbol()->symbol), _position(trade.position()),
      _orderQty(trade.orderQty()), _orderPrice(trade.orderPrice()),
      _recvCurrency(trade.recvCurrency()),
      _usedCurrency(trade.usedCurrency()) {};

auto StaticTrade::symbol() const -> const std::string { return _symbol; }

auto StaticTrade::position() const -> enum Position { return _position; }

auto StaticTrade::orderQty() const -> PreciseNumber { return _orderQty; }

auto StaticTrade::orderPrice() const -> PreciseNumber { return _orderPrice; }

auto StaticTrade::recvCurrency() const -> std::string { return _recvCurrency; }

auto StaticTrade::usedCurrency() const -> std::string { return _usedCurrency; }

auto StaticTrade::operator==(const StaticTrade &other) const -> bool {
  return _symbol == other._symbol && _position == other._position &&
         _orderQty == other._orderQty && _orderPrice == other._orderPrice &&
         _recvCurrency == other._recvCurrency &&
         _usedCurrency == other._usedCurrency;
}