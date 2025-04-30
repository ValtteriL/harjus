#pragma once

#include "Trade.h"
#include <boost/multiprecision/cpp_dec_float.hpp>
#include <string>

/**
 * @brief Execution interface.
 * This interface represents the execution of a series of trades.
 * It provides methods to recalculate the associated opportunity and get key
 * details
 */

class IExecution {
public:
  /**
   * @brief Recalculate the opportunity associated with the execution.
   * @details This method should be called after a price update that affects
   * this execution to update the total profit.
   */
  virtual void
  update(boost::multiprecision::cpp_dec_float_50 startingAssetBudget) = 0;

  /**
   * @brief Get the total profit
   * @return The total profit of the execution in relative value.
   */
  virtual boost::multiprecision::cpp_dec_float_50 getTotalProfit() const = 0;

  /**
   * @brief Get the starting asset.
   * @return Get the asset symbol that is used to start the series of trades.
   */
  virtual std::string getStartingAsset() const = 0;

  /**
   * @brief Get the capacity of the execution.
   * @details This method returns the maximum amount of the starting asset
   * that can be used in the execution.
   * @return The capacity of the execution in the starting asset.
   */
  virtual boost::multiprecision::cpp_dec_float_50 getCapacity() const = 0;

  /**
   * @brief Get the trades associated with the execution.
   * @return A vector of trades associated with the execution.
   */
  virtual std::vector<Trade> &getTrades() = 0;
};
