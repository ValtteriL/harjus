#pragma once

#include "StaticTrade.h"
#include "Trade.h"
#include <shared_mutex>
#include <unordered_set>
#include <utility> // for std::pair
#include <vector>

/**
 * ReservedTrades class. Contains logic for bookkeeping reserved trades.
 * This class is used to reserve trades that are currently being processed
 * to avoid consuming offers for symbol multiple times.
 * Trades with same symbol and position are treated as equal.
 */

class ReservedTrades {
private:
  /**
   *  Custom hash and equality for Trade symbol and position pair.
   */
  struct PairHash {
    std::size_t operator()(const std::pair<std::string, Position> &pair) const {
      return std::hash<std::string>()(pair.first) ^
             std::hash<Position>()(pair.second);
    }
  };

  struct PairEqual {
    bool operator()(const std::pair<std::string, Position> &lhs,
                    const std::pair<std::string, Position> &rhs) const {
      return lhs.first == rhs.first && lhs.second == rhs.second;
    }
  };

  /**
   *  Reserved symbols list using pairs of symbol string and position.
   */
  std::unordered_set<std::pair<std::string, Position>, PairHash, PairEqual>
      _reservedTrades;

  /**
   * Mutex for thread safety.
   */
  std::shared_mutex mtx;

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
   *  Release a trade by StaticTrade.
   */
  void release(const StaticTrade &staticTrade);

  /**
   * @brief Release all trades in vector.
   * @param trades Vector of trades to release.
   */
  void releaseAll(std::vector<StaticTrade> &trades);

  /**
   *  Check if a trade is reserved.
   */
  bool isReserved(Trade &trade);

  /**
   *  Check if a trade is reserved.
   */
  bool isReserved(std::vector<Trade> &trades);
};
