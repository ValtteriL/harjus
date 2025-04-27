#pragma once

#include "IExecution.h"
#include "ITrade.h"
#include <vector>

/**
 * @brief Configuration class that implements IExecution interface.
 */

class Execution : public IExecution {
private:
  std::vector<ITrade> &_trades;
  std::string _startingAsset;
  const boost::multiprecision::cpp_dec_float_50 _commission;
  const boost::multiprecision::cpp_dec_float_50 _relativeValue;
  const boost::multiprecision::cpp_dec_float_50 _totalProfit;

public:
  /**
   * @brief Constructor for Execution class.
   * @param trades A vector of trades associated with the execution.
   * @param commission Commission percentage per trade.
   * @param relativeValue The relative value of the starting asset.
   */
  Execution(std::vector<ITrade> &trades, std::string startingAsset,
            boost::multiprecision::cpp_dec_float_50 relativeValue,
            boost::multiprecision::cpp_dec_float_50 commission)
      : _trades(trades), _startingAsset(startingAsset), _commission(commission),
        _relativeValue(relativeValue) {}

  void update() override;

  boost::multiprecision::cpp_dec_float_50 getTotalProfit() const override;

  std::string getStartingAsset() const override;
};