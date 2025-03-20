#include <QMultiHash>
#include <QList>
#include <QHash>
#include <QJsonObject>
#include "plannedexecution.h"

class Engine
{
public:
  static Engine fromJson(const QJsonObject &json);
  QList<PlannedExecution> orderedPlannedExecutionsForPriceUpdate(const QString &symbol, double bidPrice, double bidQty, double askPrice, double askQty);

private:
  struct offer
  {
    double mPrice;
    double mQty;
  };

  struct best_offers
  {
    offer &mBid;
    offer &mAsk;
  };

  double mCommission;
  QMultiHash<QString, QList<PlannedExecution &> &> mSymbol_to_trading_paths;
  QHash<QString, best_offers &> mSymbol_to_best_offers;
};