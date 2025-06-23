#include "Trade.h"
#include <cmath>

Trade::Trade(const Symbol *symbol, Position position)
    : _symbol(symbol), _position(position), _orderQty(offerQty()),
      _recvCurrency(position == Position::LONG ? symbol->baseAsset
                                               : symbol->quoteAsset),
      _usedCurrency(position == Position::LONG ? symbol->quoteAsset
                                               : symbol->baseAsset) {}

auto Trade::position() const -> enum Position { return _position; }

auto Trade::orderQty() const -> PreciseNumber { return _orderQty; }

void Trade::resetOrderQty() { _orderQty = offerQty(); }

auto Trade::orderPrice() const -> PreciseNumber {
  return _position == Position::LONG ? _symbol->askPrice : _symbol->bidPrice;
}

auto Trade::offerQty() const -> PreciseNumber {
  return _position == Position::LONG ? _symbol->askQty : _symbol->bidQty;
}

auto Trade::symbol() const -> const Symbol * { return _symbol; }

void Trade::recalculateOrderQty(const PreciseNumber &budget) {

  PreciseNumber budgetOrderQty =
      _position == Position::LONG ? budget / orderPrice() : budget;

  // ensure Qty is multiple of baseAssetIncrement (step size)
  budgetOrderQty =
      budgetOrderQty -
      PreciseNumber::fmod(budgetOrderQty, _symbol->baseAssetIncrement);

  auto maxOrderQty = PreciseNumber::min(budgetOrderQty, offerQty());

  // ensure order value is gte minNotional
  if (maxOrderQty * orderPrice() < _symbol->minNotional) {
    _orderQty = PreciseNumber{"0"};
  } else {
    _orderQty = maxOrderQty;
  }
}

auto Trade::recvQty() const -> PreciseNumber {
  if (_position == Position::LONG) {
    return _orderQty;
  } else {
    return _orderQty * orderPrice();
  }
}

auto Trade::usedQty() const -> PreciseNumber {
  if (_position == Position::LONG) {
    return _orderQty * orderPrice();
  } else {
    return _orderQty;
  }
}

auto Trade::recvCurrency() const -> std::string { return _recvCurrency; }

auto Trade::usedCurrency() const -> std::string { return _usedCurrency; }

auto Trade::operator==(const Trade &other) const -> bool {
  return symbol()->symbol == other.symbol()->symbol &&
         position() == other.position() && orderQty() == other.orderQty();
}
