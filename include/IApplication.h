#pragma once

#include "Position.h"
#include "PreciseNumber.h"
#include <string>

/**
 * @brief Application interface.
 * This interface includes the custom functions that are called outside the FIX
 * application
 */

class IApplication {
public:
  /**
   * @brief Subscribe to market data for a list of symbols
   * @param symbols Vector of trading symbols to subscribe to
   * @return true if subscription request was sent successfully, false
   * otherwise
   */
  virtual bool subscribeToSymbols(const std::vector<std::string> &symbols) = 0;

  /**
   * @brief Submit new Market order.
   * @details Submit new market order with FOK using the order entry session
   * @param id Order ID
   * @param symbol Trading symbol
   * @param qty Order quantity
   * @param price Order price
   * @param position Position to buy/sell
   */
  virtual void submitOrder(const std::string &id, const std::string &symbol,
                           const PreciseNumber qty, const PreciseNumber price,
                           const Position position) = 0;
};
