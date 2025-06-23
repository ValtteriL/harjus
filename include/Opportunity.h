#pragma once

#include "IOpportunity.h"
#include "Trade.h"
#include <vector>

/**
 * @brief Configuration class that implements IOpportunity interface.
 */

class Opportunity : public IOpportunity {
private:
  std::vector<Trade> *_trades;
  std::string _startingAsset;
  PreciseNumber _commission;
  PreciseNumber _relativeValue;
  PreciseNumber _totalProfit;

public:
  virtual ~Opportunity() = default;
  /**
   * @brief Constructor for Opportunity class.
   * @param trades A vector of trades associated with the execution.
   * @param commission Commission percentage per trade.
   * @param relativeValue The relative value of the starting asset.
   */
  Opportunity(std::vector<Trade> &trades, const PreciseNumber &relativeValue,
              const PreciseNumber &commission);

  void update(const PreciseNumber startingAssetBudget) override;

  [[nodiscard]] auto getTotalProfit() const -> PreciseNumber override;

  [[nodiscard]] auto getStartingAsset() const -> std::string override;

  [[nodiscard]] auto getCapacity() const -> PreciseNumber override;

  [[nodiscard]] auto getTrades() const -> std::vector<Trade> & override;
};