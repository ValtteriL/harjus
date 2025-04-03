#pragma once

#include "Position.h"
#include "TradingSymbol.h"

class ITrade
{
public:
  virtual Position getPosition() const = 0;
  virtual long double getOrderQty() const = 0;
  virtual long double getOrderPrice() const = 0;
  virtual const std::string &getSymbol() const = 0;
  virtual void setBudget(long double budget) = 0;
  virtual long double getRecvQty() const = 0;
  virtual long double getUsedQty() const = 0;
  virtual std::string_view getRecvCurrency() const = 0;
  virtual std::string_view getUsedCurrency() const = 0;

  /**
   * Compare two trades for equality. This is used to check if a trade is already reserved.
   * This ensures that trades with the same symbol and position are treated as the same.
   */
  bool operator==(const ITrade &other) const
  {
    return getSymbol() == other.getSymbol() && getPosition() == other.getPosition() && getOrderQty() == other.getOrderQty();
  }

  /**
   * Hash function for Trade.
   * Combines the hash of the symbol and position to create a unique hash for the trade.
   * This ensures that trades with the same symbol and position are treated as the same.
   */
  std::size_t hash() const
  {
    return std::hash<std::string>()(getSymbol()) ^ std::hash<Position>()(getPosition());
  }
};

// Specialization of std::hash for Trade
namespace std
{
  template <>
  struct hash<ITrade>
  {
    std::size_t operator()(const ITrade &trade) const
    {
      return trade.hash();
    }
  };
}