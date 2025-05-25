#pragma once

#include "Opportunity.h"
#include "PreciseNumber.h"
#include "StaticTrade.h"
#include "Trade.h"
#include <queue>
#include <vector>

/**
 * @file Execution.h
 * @brief Representation of a series of trades with fixed prices and quantities.
 * @details This class is a "frozen" opportunity, meaning thatthe trade
 * parameters are unaffected by price updates. This fixed form is used by trader
 * to execute the trades.
 */

class Execution {
private:
  std::queue<StaticTrade> _trades;
  std::vector<StaticTrade> _tradesVector;
  std::string _startingAsset;
  PreciseNumber _totalProfit;
  PreciseNumber _capacity;

public:
  /**
   * @brief Constructor for Execution class.
   * @param opportunity Opportunity object to be frozen
   */
  Execution(Opportunity &opportunity);

  /**
   * @brief Default constructor for Execution class.
   */
  Execution() = default;

  virtual ~Execution() = default; // Add a virtual destructor

  /**
   * @brief Copy assignment operator for Execution class.
   * @param other The Execution object to copy from.
   * @return A reference to this Execution object.
   */
  Execution &operator=(const Execution &other) {
    if (this != &other) {
      _trades = other._trades;
      _tradesVector = other._tradesVector;
      _startingAsset = other._startingAsset;
      _totalProfit = other._totalProfit;
      _capacity = other._capacity;
    }
    return *this;
  }

  /**
   * @brief Copy constructor
   */
  Execution(const Execution &other) = default;

  /**
   * @brief equality operator for Execution
   */
  bool operator==(const Execution &other) const {
    return this->_tradesVector == other._tradesVector;
  }

  /**
   * @brief Recalculate the opportunity associated with the
   * opportunity.
   * @details This method should be called after a price update that affects
   * this opportunity to update the total profit.
   */
  void update(const PreciseNumber startingAssetBudget);

  /**
   * @brief Get the total profit
   * @return The total profit of the opportunity in relative value.
   */
  PreciseNumber getTotalProfit() const;

  /**
   * @brief Get the capacity of the opportunity.
   * @details This method returns the maximum amount of the starting asset
   * that can be used in the opportunity.
   * @return The capacity of the opportunity in the starting asset.
   */

  PreciseNumber getCapacity() const;

  /**
   * @brief Get the starting asset.
   * @return Get the asset symbol that is used to start the series of trades.
   */
  std::string getStartingAsset() const;

  /**
   * @brief Get the trades associated with the execution.
   * @return A queue of trades associated with the execution.
   */
  std::queue<StaticTrade> &getTrades();

  /**
   * @brief Get the original trades associated with the execution.
   * @return A vector of trades associated with the execution since
   * construction.
   */
  std::vector<StaticTrade> &getOriginalTrades() { return _tradesVector; }

  /**
   * @brief Stream operator overload for Execution
   * @param os Output stream
   * @param execution Execution object to print
   * @return Reference to the output stream
   */
  friend std::ostream &operator<<(std::ostream &os, const Execution &execution);
};