#pragma once

#include <QMultiHash>
#include <QList>
#include <QHash>
#include <QJsonObject>
#include <QJsonArray>
#include "plannedexecution.h"
#include "offer.h"

class Engine
{
public:
  static Engine fromJson(const QJsonObject &json);
  Engine(QMultiHash<QString, PlannedExecution> symbolToPlannedExecutions, QHash<QString, Offer> symbolToOffer) : mSymbolToPlannedExecutions(symbolToPlannedExecutions), mSymbolToOffer(symbolToOffer) {};
  QList<PlannedExecution> priceUpdate(const QJsonObject &json);

private:
  QMultiHash<QString, PlannedExecution> mSymbolToPlannedExecutions;
  QHash<QString, Offer> mSymbolToOffer;
};