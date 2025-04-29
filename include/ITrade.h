#pragma once

#include "Position.h"
#include "Symbol.h"
#include <boost/multiprecision/cpp_dec_float.hpp>

class ITrade {
public:
  virtual enum Position getPosition() const = 0;
  virtual boost::multiprecision::cpp_dec_float_50 getOrderQty() const = 0;
  virtual boost::multiprecision::cpp_dec_float_50 getOrderPrice() const = 0;
  virtual const Symbol &getSymbol() const = 0;
  virtual void setBudget(boost::multiprecision::cpp_dec_float_50 budget) = 0;
  virtual boost::multiprecision::cpp_dec_float_50 getRecvQty() const = 0;
  virtual boost::multiprecision::cpp_dec_float_50 getUsedQty() const = 0;
  virtual std::string getRecvCurrency() const = 0;
  virtual std::string getUsedCurrency() const = 0;

  /**
   * Compare two trades for equality. This is used to check if a trade is
   * already reserved. This ensures that trades with the same symbol and
   * position are treated as the same.
   */
  bool operator==(const ITrade &other) const {
    return getSymbol().symbol == other.getSymbol().symbol &&
           getPosition() == other.getPosition() &&
           getOrderQty() == other.getOrderQty();
  }

  /**
   * Hash function for Trade.
   * Combines the hash of the symbol and position to create a unique hash for
   * the trade. This ensures that trades with the same symbol and position are
   * treated as the same.
   */
  std::size_t hash() const {
    return std::hash<std::string>()(getSymbol().symbol) ^
           std::hash<Position>()(getPosition());
  }
};

// Specialization of std::hash for Trade
namespace std {
template <> struct hash<ITrade> {
  std::size_t operator()(const ITrade &trade) const { return trade.hash(); }
};
} // namespace std