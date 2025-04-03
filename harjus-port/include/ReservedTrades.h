#pragma once

#include <unordered_set>
#include "ITrade.h"

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
  void reserve(ITrade &trade);

  /**
   *  Release a trade.
   */
  void release(ITrade &trade);

  /**
   *  Check if a trade is reserved.
   */
  bool isReserved(ITrade &trade) const;

private:
  /**
   *  Custom hash and equality for ITrade.
   */
  struct ITradeHash
  {
    std::size_t operator()(const ITrade *trade) const
    {
      return trade->hash();
    }
  };

  struct ITradeEqual
  {
    bool operator()(const ITrade *lhs, const ITrade *rhs) const
    {
      return *lhs == *rhs;
    }
  };

  /**
   *  Reserved symbols list.
   */
  std::unordered_set<ITrade *, ITradeHash, ITradeEqual> reservedTrades;
};
;
