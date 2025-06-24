#pragma once

#include "PreciseNumber.h"
#include "Trade.h"
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
  virtual void update(const PreciseNumber startingAssetBudget) = 0;

  /**
   * @brief Get the total profit
   * @return The total profit of the opportunity in relative value.
   */
  [[nodiscard]] virtual auto getTotalProfit() const -> PreciseNumber = 0;

  /**
   * @brief Get the starting asset.
   * @return Get the asset symbol that is used to start the series of trades.
   */
  [[nodiscard]] virtual auto getStartingAsset() const -> std::string = 0;

  /**
   * @brief Get the capacity of the opportunity.
   * @details This method returns the maximum amount of the starting asset
   * that can be used in the opportunity.
   * @return The capacity of the opportunity in the starting asset.
   */
  [[nodiscard]] virtual auto getCapacity() const -> PreciseNumber = 0;

  /**
   * @brief Get the trades associated with the opportunity.
   * @return A vector of trades associated with the opportunity.
   */
  [[nodiscard]] virtual auto getTrades() const -> std::vector<Trade> = 0;
};
