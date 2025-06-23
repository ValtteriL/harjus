#pragma once

#include "IOpportunity.h"
#include "Trade.h"
#include <vector>

/**
 * @brief Configuration class that implements IOpportunity interface.
 */

class Opportunity : public IOpportunity {
private:
  std::vector<Trade> &_trades;
  const std::string _startingAsset;
  const PreciseNumber _commission;
  const PreciseNumber _relativeValue;
  PreciseNumber _totalProfit;

public:
  /**
   * @brief Constructor for Opportunity class.
   * @param trades A vector of trades associated with the execution.
   * @param commission Commission percentage per trade.
   * @param relativeValue The relative value of the starting asset.
   */
  Opportunity(std::vector<Trade> &trades, const PreciseNumber &relativeValue,
              const PreciseNumber &commission);

  void update(const PreciseNumber startingAssetBudget) override;

  PreciseNumber getTotalProfit() const override;

  std::string getStartingAsset() const override;

  PreciseNumber getCapacity() const override;

  std::vector<Trade> &getTrades() const override;
};