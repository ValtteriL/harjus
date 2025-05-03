#pragma once

#include "Trade.h"
#include <unordered_set>

/**
 * ReservedTrades class. Contains logic for bookkeeping reserved trades.
 * This class is used to reserve trades that are currently being processed
 * to avoid consuming offers for symbol multiple times.
 * Trades with same symbol and position are treated as equal.
 */

class ReservedTrades {
public:
  /**
   *  Constructor. Create a new reserved trades object.
   */
  ReservedTrades() = default;

  /**
   *  Reserve a trade.
   */
  void reserve(Trade &trade);

  /**
   *  Release a trade.
   */
  void release(Trade &trade);

  /**
   * @brief Release all trades in vector.
   * @param trades Vector of trades to release.
   */
  void releaseAll(std::vector<Trade *> &trades);

  /**
   *  Check if a trade is reserved.
   */
  bool isReserved(Trade &trade) const;

private:
  /**
   *  Custom hash and equality for Trade.
   */
  struct TradeHash {
    std::size_t operator()(const Trade *trade) const { return trade->hash(); }
  };

  struct TradeEqual {
    bool operator()(const Trade *lhs, const Trade *rhs) const {
      return *lhs == *rhs;
    }
  };

  /**
   *  Reserved symbols list.
   */
  std::unordered_set<Trade *, TradeHash, TradeEqual> reservedTrades;
};
;
