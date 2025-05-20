#include "Trade.h"
#include <cmath>

Trade::Trade(const Symbol *symbol, Position position)
    : _symbol(symbol), _position(position), _orderQty(offerQty()),
      _recvCurrency(position == Position::LONG ? symbol->baseAsset
                                               : symbol->quoteAsset),
      _usedCurrency(position == Position::LONG ? symbol->quoteAsset
                                               : symbol->baseAsset) {}

enum Position Trade::position() const { return _position; }

boost::multiprecision::cpp_dec_float_50 Trade::orderQty() const {
  return _orderQty;
}

void Trade::resetOrderQty() { _orderQty = offerQty(); }

boost::multiprecision::cpp_dec_float_50 Trade::orderPrice() const {
  return _position == Position::LONG ? _symbol->askPrice : _symbol->bidPrice;
}

boost::multiprecision::cpp_dec_float_50 Trade::offerQty() const {
  return _position == Position::LONG ? _symbol->askQty : _symbol->bidQty;
}

const Symbol *Trade::symbol() const { return _symbol; }

void Trade::recalculateOrderQty(
    boost::multiprecision::cpp_dec_float_50 budget) {

  boost::multiprecision::cpp_dec_float_50 budgetOrderQty = 0;

  if (_position == Position::LONG) {

    auto temp = budget / orderPrice();
    // ensure Qty is multiple of minNotional
    budgetOrderQty = temp - fmod(temp, _symbol->minNotional);
  } else {
    // ensure Qty is multiple of minNotional
    budgetOrderQty = budget - fmod(budget, _symbol->minNotional);
  }

  // ensure Qty is multiple of baseAssetIncrement (step size)
  budgetOrderQty =
      budgetOrderQty - fmod(budgetOrderQty, _symbol->baseAssetIncrement);

  auto maxOrderQty = boost::multiprecision::min(budgetOrderQty, offerQty());

  // ensure order value is gte minNotional
  if (maxOrderQty * orderPrice() < _symbol->minNotional) {
    _orderQty = 0;
  } else {
    _orderQty = maxOrderQty;
  }
}

boost::multiprecision::cpp_dec_float_50 Trade::recvQty() const {
  if (_position == Position::LONG) {
    return _orderQty;
  } else {
    return _orderQty * orderPrice();
  }
}

boost::multiprecision::cpp_dec_float_50 Trade::usedQty() const {
  if (_position == Position::LONG) {
    return _orderQty * orderPrice();
  } else {
    return _orderQty;
  }
}

std::string Trade::recvCurrency() const { return _recvCurrency; }

std::string Trade::usedCurrency() const { return _usedCurrency; }

bool Trade::operator==(const Trade &other) const {
  return symbol()->symbol == other.symbol()->symbol &&
         position() == other.position() && orderQty() == other.orderQty();
}
