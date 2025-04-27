#include "Trade.h"

enum Position Trade::getPosition() const { return position_; }

boost::multiprecision::cpp_dec_float_50 Trade::getOrderQty() const {
  return orderQty_;
}

boost::multiprecision::cpp_dec_float_50 Trade::getOrderPrice() const {
  return orderPrice_;
}

const Symbol &Trade::getSymbol() const { return symbol_; }

void Trade::setBudget(boost::multiprecision::cpp_dec_float_50 budget) {
  if (position_ == Position::LONG) {
    auto budgetOrderPrice = budget / orderPrice_;
    orderQty_ = boost::multiprecision::min(budgetOrderPrice, offerQty_);
  } else {
    orderQty_ = boost::multiprecision::min(offerQty_, budget);
  }
}

boost::multiprecision::cpp_dec_float_50 Trade::getRecvQty() const {
  if (position_ == Position::LONG) {
    return orderQty_;
  } else {
    return orderQty_ * orderPrice_;
  }
}

boost::multiprecision::cpp_dec_float_50 Trade::getUsedQty() const {
  if (position_ == Position::LONG) {
    return orderQty_ * orderPrice_;
  } else {
    return orderQty_;
  }
}

std::string_view Trade::getRecvCurrency() const { return recvCurrency_; }

std::string_view Trade::getUsedCurrency() const { return usedCurrency_; }
