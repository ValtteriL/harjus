#include "Trade.h"
#include <cmath>

Trade::Trade(const Symbol *symbol, Position position)
    : _symbol(symbol), _position(position), _orderQty(getOfferQty()),
      _recvCurrency(position == Position::LONG ? symbol->baseAsset
                                               : symbol->quoteAsset),
      _usedCurrency(position == Position::LONG ? symbol->quoteAsset
                                               : symbol->baseAsset) {}

enum Position Trade::getPosition() const { return _position; }

boost::multiprecision::cpp_dec_float_50 Trade::getOrderQty() const {
  return _orderQty;
}

void Trade::resetOrderQty() { _orderQty = getOfferQty(); }

boost::multiprecision::cpp_dec_float_50 Trade::getOrderPrice() const {
  return _position == Position::LONG ? _symbol->askPrice : _symbol->bidPrice;
}

boost::multiprecision::cpp_dec_float_50 Trade::getOfferQty() const {
  return _position == Position::LONG ? _symbol->askQty : _symbol->bidQty;
}

const Symbol *Trade::getSymbol() const { return _symbol; }

void Trade::setBudget(boost::multiprecision::cpp_dec_float_50 budget) {

  boost::multiprecision::cpp_dec_float_50 budgetOrderQty = 0;

  if (_position == Position::LONG) {

    auto temp = budget / getOrderPrice();
    // ensure Qty is multiple of minNotional
    budgetOrderQty = temp - fmod(temp, _symbol->minNotional);

  } else {
    // ensure Qty is multiple of minNotional
    budgetOrderQty = budget - fmod(budget, _symbol->minNotional);
  }

  auto maxOrderQty = boost::multiprecision::min(budgetOrderQty, getOfferQty());

  // ensure order value is gte minNotional
  if (maxOrderQty * getOrderPrice() < _symbol->minNotional) {
    _orderQty = 0;
  } else {
    _orderQty = maxOrderQty;
  }
}

boost::multiprecision::cpp_dec_float_50 Trade::getRecvQty() const {
  if (_position == Position::LONG) {
    return _orderQty;
  } else {
    return _orderQty * getOrderPrice();
  }
}

boost::multiprecision::cpp_dec_float_50 Trade::getUsedQty() const {
  if (_position == Position::LONG) {
    return _orderQty * getOrderPrice();
  } else {
    return _orderQty;
  }
}

std::string Trade::getRecvCurrency() const { return _recvCurrency; }

std::string Trade::getUsedCurrency() const { return _usedCurrency; }

bool Trade::operator==(const Trade &other) const {
  return getSymbol()->symbol == other.getSymbol()->symbol &&
         getPosition() == other.getPosition() &&
         getOrderQty() == other.getOrderQty();
}

std::size_t Trade::hash() const {
  return std::hash<std::string>()(getSymbol()->symbol) ^
         std::hash<Position>()(getPosition());
}