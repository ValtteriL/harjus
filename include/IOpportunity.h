#pragma once

#include "Trade.h"
#include <boost/multiprecision/cpp_dec_float.hpp>
#include <string>

/**
 * @brief Opportunity interface.
 * This interface represents the opportunity of a series of trades.
 * It provides methods to recalculate the associated opportunity and get key
 * details
 */

class IOpportunity {
public:
  /**
   * @brief Recalculate the opportunity associated with the opportunity.
   * @details This method should be called after a price update that affects
   * this opportunity to update the total profit.
   */
  virtual void
  update(boost::multiprecision::cpp_dec_float_50 startingAssetBudget) = 0;

  /**
   * @brief Get the total profit
   * @return The total profit of the opportunity in relative value.
   */
  virtual boost::multiprecision::cpp_dec_float_50 getTotalProfit() const = 0;

  /**
   * @brief Get the starting asset.
   * @return Get the asset symbol that is used to start the series of trades.
   */
  virtual std::string getStartingAsset() const = 0;

  /**
   * @brief Get the capacity of the opportunity.
   * @details This method returns the maximum amount of the starting asset
   * that can be used in the opportunity.
   * @return The capacity of the opportunity in the starting asset.
   */
  virtual boost::multiprecision::cpp_dec_float_50 getCapacity() const = 0;

  /**
   * @brief Get the trades associated with the opportunity.
   * @return A vector of trades associated with the opportunity.
   */
  virtual std::vector<Trade> &getTrades() = 0;
};
