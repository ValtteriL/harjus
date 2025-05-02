#pragma once

#include "Opportunity.h"
#include "Trade.h"
#include <boost/multiprecision/cpp_dec_float.hpp>

/**
 * @file Execution.h
 * @brief Representation of a series of trades with fixed prices and quantities.
 * @details This class is a "frozen" opportunity, meaning thatthe trade
 * parameters are unaffected by price updates. This fixed form is used by trader
 * to execute the trades.
 */

class Execution : public IOpportunity {
private:
  std::vector<Trade> _trades;
  std::string _startingAsset;
  boost::multiprecision::cpp_dec_float_50 _totalProfit;

public:
  /**
   * @brief Constructor for Execution class.
   * @param opportunity Opportunity object to be frozen
   */
  Execution(Opportunity &opportunity);

  virtual ~Execution() = default; // Add a virtual destructor

  /**
   * @brief Recalculate the opportunity associated with the
   * opportunity.
   * @details This method should be called after a price update that affects
   * this opportunity to update the total profit.
   */
  void
  update(boost::multiprecision::cpp_dec_float_50 startingAssetBudget) override;

  /**
   * @brief Get the total profit
   * @return The total profit of the opportunity in relative value.
   */
  boost::multiprecision::cpp_dec_float_50 getTotalProfit() const override;

  /**
   * @brief Get the capacity of the opportunity.
   * @details This method returns the maximum amount of the starting asset
   * that can be used in the opportunity.
   * @return The capacity of the opportunity in the starting asset.
   */

  boost::multiprecision::cpp_dec_float_50 getCapacity() const override;

  /**
   * @brief Get the starting asset.
   * @return Get the asset symbol that is used to start the series of trades.
   */
  std::string getStartingAsset() const override;

  /**
   * @brief Get the trades associated with the execution.
   * @return A vector of trades associated with the execution.
   */
  std::vector<Trade> &getTrades() override;
};