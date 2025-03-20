#include <QList>
#include <QJsonObject>
#include "tradingsymbol.h"

class PlannedExecution
{
public:
  double totalProfit() const { return mTotalProfit; }
  void update();
  QJsonObject toJson() const;

private:
  QList<TradingSymbol> mTrades;
  double mTotalProfit;
  double mRelativePrice;
  double mCommission;
};