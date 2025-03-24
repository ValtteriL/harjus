#pragma once

#include <QJsonObject>
#include "tradingsymbol.h"

class PlannedExecution
{
public:
  long double totalProfit() const { return mTotalProfit; }
  void update();
  QJsonObject toJson() const;
  PlannedExecution(std::vector<TradingSymbol> trades, long double relativePrice, long double commission) : mTrades{trades}, mTotalProfit{0}, mRelativePrice(relativePrice), mCommission(commission) {};

private:
  std::vector<TradingSymbol> mTrades;
  long double mTotalProfit;
  long double mRelativePrice;
  long double mCommission;
};