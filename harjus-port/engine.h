#include <QMultiHash>
#include <QList>
#include <QHash>
#include <QJsonObject>
#include "plannedexecution.h"
#include "offer.h"

class Engine
{
public:
  static Engine fromJson(const QJsonObject &json);
  QList<PlannedExecution> priceUpdate(const QString &symbol, double bidPrice, double bidQty, double askPrice, double askQty);

private:
  QMultiHash<QString, PlannedExecution &> mSymbolToPlannedExecutions;
  QHash<QString, Offer &> mSymbolToOffer;
};