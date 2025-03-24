#include "plannedexecution.h"
#include <QJsonArray>

void PlannedExecution::update()
{
  // TODO
}

/*
      {
        "total_profit": "0.0001",
        "trades": [
          ...
        ]
      },
*/

QJsonObject PlannedExecution::toJson() const
{
  QJsonObject json;

  json["total_profit"] = mTotalProfit;

  QJsonArray tradeArray;
  for (const TradingSymbol &ts : mTrades)
    tradeArray.append(ts.toJson());
  json["trades"] = tradeArray;

  return json;
}
