#include "Trade.h"
#include <cmath>

Trade::Trade(const Symbol *symbol, Position position)
    : _symbol(symbol), _position(position), _orderQty(offerQty()),
      _recvCurrency(position == Position::LONG ? symbol->baseAsset
                                               : symbol->quoteAsset),
      _usedCurrency(position == Position::LONG ? symbol->quoteAsset
                                               : symbol->baseAsset) {}

enum Position Trade::position() const { return _position; }

PreciseNumber Trade::orderQty() const { return _orderQty; }

void Trade::resetOrderQty() { _orderQty = offerQty(); }

PreciseNumber Trade::orderPrice() const {
  return _position == Position::LONG ? _symbol->askPrice : _symbol->bidPrice;
}

PreciseNumber Trade::offerQty() const {
  return _position == Position::LONG ? _symbol->askQty : _symbol->bidQty;
}

const Symbol *Trade::symbol() const { return _symbol; }

void Trade::recalculateOrderQty(PreciseNumber budget) {

  PreciseNumber budgetOrderQty = 0;

  if (_position == Position::LONG) {

    auto temp = budget / orderPrice();
    // ensure Qty is multiple of minNotional
    budgetOrderQty = temp - PreciseNumber::fmod(temp, _symbol->minNotional);
  } else {
    // ensure Qty is multiple of minNotional
    budgetOrderQty = budget - PreciseNumber::fmod(budget, _symbol->minNotional);
  }

  // ensure Qty is multiple of baseAssetIncrement (step size)
  budgetOrderQty =
      budgetOrderQty - PreciseNumber::fmod(budgetOrderQty, _symbol->baseAssetIncrement);

  auto maxOrderQty = PreciseNumber::min(budgetOrderQty, offerQty());

  // ensure order value is gte minNotional
  if (maxOrderQty * orderPrice() < _symbol->minNotional) {
    _orderQty = 0;
  } else {
    _orderQty = maxOrderQty;
  }
}

PreciseNumber Trade::recvQty() const {
  if (_position == Position::LONG) {
    return _orderQty;
  } else {
    return _orderQty * orderPrice();
  }
}

PreciseNumber Trade::usedQty() const {
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
