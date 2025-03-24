#pragma once

#include <QJsonObject>
#include "tradingsymbol.h"

class PlannedExecution
{
public:
  double totalProfit() const { return mTotalProfit; }
  void update();
  QJsonObject toJson() const;
  PlannedExecution(std::vector<TradingSymbol> trades, double relativePrice, double commission) : mTrades{trades}, mTotalProfit{0}, mRelativePrice(relativePrice), mCommission(commission) {};

private:
  std::vector<TradingSymbol> mTrades;
  double mTotalProfit;
  double mRelativePrice;
  double mCommission;
};