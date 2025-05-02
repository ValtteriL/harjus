#include "Trade.h"

Trade::Trade(const Symbol &symbol, Position position)
    : symbol_(symbol), position_(position), orderQty_(getOfferQty()),
      recvCurrency_(position == Position::LONG ? symbol.baseAsset
                                               : symbol.quoteAsset),
      usedCurrency_(position == Position::LONG ? symbol.quoteAsset
                                               : symbol.baseAsset) {}

enum Position Trade::getPosition() const { return position_; }

boost::multiprecision::cpp_dec_float_50 Trade::getOrderQty() const {
  return orderQty_;
}

boost::multiprecision::cpp_dec_float_50 Trade::getOrderPrice() const {
  return position_ == Position::LONG ? symbol_.askPrice : symbol_.bidPrice;
}

boost::multiprecision::cpp_dec_float_50 Trade::getOfferQty() const {
  return position_ == Position::LONG ? symbol_.askQty : symbol_.bidQty;
}

const Symbol &Trade::getSymbol() const { return symbol_; }

void Trade::setBudget(boost::multiprecision::cpp_dec_float_50 budget) {
  if (position_ == Position::LONG) {
    auto budgetOrderPrice = budget / getOrderPrice();
    orderQty_ = boost::multiprecision::min(budgetOrderPrice, getOfferQty());
  } else {
    orderQty_ = boost::multiprecision::min(getOfferQty(), budget);
  }
}

boost::multiprecision::cpp_dec_float_50 Trade::getRecvQty() const {
  if (position_ == Position::LONG) {
    return orderQty_;
  } else {
    return orderQty_ * getOrderPrice();
  }
}

boost::multiprecision::cpp_dec_float_50 Trade::getUsedQty() const {
  if (position_ == Position::LONG) {
    return orderQty_ * getOrderPrice();
  } else {
    return orderQty_;
  }
}

std::string Trade::getRecvCurrency() const { return recvCurrency_; }

std::string Trade::getUsedCurrency() const { return usedCurrency_; }

bool Trade::operator==(const Trade &other) const {
  return getSymbol().symbol == other.getSymbol().symbol &&
         getPosition() == other.getPosition() &&
         getOrderQty() == other.getOrderQty();
}

std::size_t Trade::hash() const {
  return std::hash<std::string>()(getSymbol().symbol) ^
         std::hash<Position>()(getPosition());
}