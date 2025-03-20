#include <QList>
#include "tradingsymbol.h"

struct PlannedExecution
{
  /* data */
  double mTotalProfit;
  QList<TradingSymbol> mTrades;
};