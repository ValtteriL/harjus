#pragma once

#include <unordered_set>
#include "Trade.h"

/**
 * ReservedTrades class. Contains logic for bookkeeping reserved trades.
 * This class is used to reserve trades that are currently being processed
 * to avoid consuming offers for symbol multiple times.
 * Trades with same symbol and position are treated as equal.
 */

class ReservedTrades
{
public:
  /**
   *  Constructor. Create a new reserved trades object.
   */
  ReservedTrades() = default;

  /**
   *  Reserve a trade.
   */
  void reserve(const Trade &trade);

  /**
   *  Release a trade.
   */
  void release(const Trade &trade);

  /**
   *  Check if a trade is reserved.
   */
  bool isReserved(const Trade &trade) const;

private:
  /**
   *  Reserved symbols list.
   */
  std::unordered_set<Trade> reservedTrades;
};
