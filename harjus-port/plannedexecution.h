#pragma once

#include <QJsonObject>
#include "tradingsymbol.h"

/**
 *  Planned Execution class. Contains all information requried to execute arbitrage opportunity.
 */

class PlannedExecution
{
public:
  /**
   *  Get total profit. In relatie price, given last update's calculations.
   */
  long double totalProfit() const { return mTotalProfit; }
  void update();
  QJsonObject toJson() const;
  PlannedExecution(std::vector<TradingSymbol> trades, long double relativePrice, long double commission) : mTrades{trades}, mTotalProfit{0}, mRelativePrice(relativePrice), mCommission(commission) {};
  std::vector<TradingSymbol> mTrades;
  long double mTotalProfit;
  long double mRelativePrice;
  long double mCommission;
};