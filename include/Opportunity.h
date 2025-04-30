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
  std::string _startingAsset;
  const boost::multiprecision::cpp_dec_float_50 _commission;
  const boost::multiprecision::cpp_dec_float_50 _relativeValue;
  boost::multiprecision::cpp_dec_float_50 _totalProfit;

public:
  /**
   * @brief Constructor for Opportunity class.
   * @param trades A vector of trades associated with the execution.
   * @param commission Commission percentage per trade.
   * @param relativeValue The relative value of the starting asset.
   */
  Opportunity(std::vector<Trade> &trades,
              boost::multiprecision::cpp_dec_float_50 relativeValue,
              boost::multiprecision::cpp_dec_float_50 commission)
      : _trades(trades), _startingAsset(trades.front().getUsedCurrency()),
        _commission(commission), _relativeValue(relativeValue) {}

  void
  update(boost::multiprecision::cpp_dec_float_50 startingAssetBudget) override;

  boost::multiprecision::cpp_dec_float_50 getTotalProfit() const override;

  std::string getStartingAsset() const override;

  boost::multiprecision::cpp_dec_float_50 getCapacity() const override;

  std::vector<Trade> &getTrades() override;
};