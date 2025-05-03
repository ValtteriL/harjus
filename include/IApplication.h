#pragma once

#include "Position.h"
#include <boost/multiprecision/cpp_dec_float.hpp>
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
  virtual void submitOrder(std::string id, std::string symbol,
                           boost::multiprecision::cpp_dec_float_50 qty,
                           boost::multiprecision::cpp_dec_float_50 price,
                           Position position) = 0;
};
