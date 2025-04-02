#pragma once

#include "Position.h"
#include "TradingSymbol.h"

class Trade
{
public:
  const TradingSymbol &symbol;
  const Position position;
  long double orderQty;

  /**
   * Compare two trades for equality. This is used to check if a trade is already reserved.
   * This ensures that trades with the same symbol and position are treated as the same.
   */
  bool operator==(const Trade &other) const
  {
    return symbol.symbol() == other.symbol.symbol() && position == other.position && orderQty == other.orderQty;
  }

  /**
   * Hash function for Trade.
   * Combines the hash of the symbol and position to create a unique hash for the trade.
   * This ensures that trades with the same symbol and position are treated as the same.
   */
  std::size_t hash() const
  {
    return std::hash<std::string>()(symbol.symbol().toStdString()) ^ std::hash<Position>()(position) ^ std::hash<long double>()(orderQty);
  }
};

// Specialization of std::hash for Trade
namespace std
{
  template <>
  struct hash<Trade>
  {
    std::size_t operator()(const Trade &trade) const
    {
      return trade.hash();
    }
  };
}