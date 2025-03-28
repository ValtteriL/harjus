#include "plannedexecution.h"
#include <QJsonArray>
#include <cmath>

long double capacity(std::vector<TradingSymbol> trades)
{
  auto maxCap = std::numeric_limits<long double>::max();
  for (auto &ts : trades)
  {
    if (ts.position() == Position::LONG)
      maxCap = std::min(maxCap, ts.maxQty() * ts.price());
    else
      maxCap = std::min(maxCap, ts.maxQty());
  }

  return maxCap;
}

void PlannedExecution::update()
{
  // calculate capacity
  auto cap = capacity(mTrades);

  // update quantitities
  auto lastcap = cap;
  for (auto &ts : mTrades)
  {
    if (ts.position() == Position::LONG)
      lastcap = ts.setQtyUpto(lastcap / ts.price());
    else
      lastcap = {ts.setQtyUpto(lastcap) * ts.price()}; // when position is short, we will receive qty * ts.price()
  }

  // calculate total profit
  // total commission = start_balance * (1 + commission)^n - start_balance
  // profit = end_balance - start_balance - commission
  // total_profit = profit * relative_price
  auto startBalance = mTrades.front().usedAmount();
  auto endBalance = mTrades.back().receiveivedAmount();

  auto totalCommission = startBalance * std::pow((1 + mCommission), mTrades.size()) - startBalance;
  auto profit = endBalance - startBalance - totalCommission;
  mTotalProfit = profit * mRelativePrice;
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

  json["total_profit"] = QString::number(mTotalProfit, 'f', 16);

  QJsonArray tradeArray;
  for (const TradingSymbol &ts : mTrades)
    tradeArray.append(ts.toJson());
  json["trades"] = tradeArray;

  return json;
}
