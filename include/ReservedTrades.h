#pragma once

#include "StaticTrade.h"
#include "Trade.h"
#include <shared_mutex>
#include <unordered_map>
#include <unordered_set>
#include <vector>

/**
 * ReservedTrades class. Contains logic for bookkeeping reserved trades.
 * This class is used to reserve trades that are currently being processed
 * to avoid consuming offers for symbol multiple times.
 * Trades with same symbol are treated as equal.
 */

class ReservedTrades {
private:
  /**
   *  Reserved symbols list using pairs of symbol string.
   */
  std::unordered_set<std::string> _reservedTrades;

  /**
   * Mutex for thread safety.
   */
  mutable std::shared_mutex mtx;

public:
  /**
   *  Constructor. Create a new reserved trades object.
   */
  ReservedTrades() = default;

  /**
   *  Reserve a vector of trades.
   */
  void reserveAll(const std::vector<Trade> &trades);

  /**
   * @brief Release all trades in vector.
   * @param trades Vector of trades to release.
   */
  void releaseAll(const std::vector<StaticTrade> &trades);

  /**
   *  Get all reserved trades.
   *  @return Vector of reserved trades.
   */
  std::unordered_set<std::string> getReservedTrades() const;
};