#include "engine.h"
#include "tradingsymbol.h"
#include "plannedexecution.h"
#include <string.h>

Engine Engine::fromJson(const QJsonObject &json)
{
  // get values from json
  double commission = std::stod(get_from_json(json, "commission").toString().toStdString());
  QJsonObject relativeAssetValues = get_from_json(json, "relative_asset_values").toObject();
  QJsonArray tradingPaths = get_from_json(json, "trading_paths").toArray();

  // Convert relativeAssetValues to a QHash<QString, double>
  QHash<QString, double> relativePrices;
  for (const auto &key : relativeAssetValues.keys())
  {
    relativePrices[key] = std::stod(relativeAssetValues[key].toString().toStdString());
  }

  QHash<QString, Offer> symbolToOffer;
  QMultiHash<QString, PlannedExecution> symbolToPlannedExecutions;

  // fill symbolToOffer
  QSet<QString> symbols;
  for (const QJsonValue &path : tradingPaths)
  {
    auto tradingSymbols = path.toArray();
    for (const auto &tradingSymbol : tradingSymbols)
    {
      auto obj = tradingSymbol.toObject();
      symbols.insert(obj["symbol"].toString());
    }
  }
  for (const auto &symbol : symbols)
  {
    symbolToOffer[symbol] = Offer{};
  }

  // fill symbolToPlannedExecutions
  for (const QJsonValue &path : tradingPaths)
  {
    // convert tradingSymbols in JSON to QList<TradingSymbol>
    auto tradingSymbols = path.toArray();
    std::vector<TradingSymbol> tradingSymbolsList;
    for (const auto &tradingSymbol : tradingSymbols)
    {
      auto obj = tradingSymbol.toObject();

      TradingSymbol ts = TradingSymbol::fromJson(obj);

      QString symbol = obj["symbol"].toString();

      double &priceReference = ts.position() == Position::LONG ? symbolToOffer[symbol].askPrice : symbolToOffer[symbol].bidPrice;
      double &maxQtyReference = ts.position() == Position::LONG ? symbolToOffer[symbol].askQty : symbolToOffer[symbol].bidQty;

      // set price and maxQty
      ts.setMaxQty(maxQtyReference);
      ts.setPrice(priceReference);

      tradingSymbolsList.push_back(ts);
    }

    // throw if tradingSymbolsList is empty
    if (tradingSymbolsList.size() == 0)
      throw std::runtime_error("tradingSymbolsList is empty");

    // create PlannedExecution
    auto usedAsset = tradingSymbolsList.at(0).usedAsset();
    auto relativeValue = relativePrices.value(usedAsset, 0.000001); // very low value if not found
    PlannedExecution execution{tradingSymbolsList, relativeValue, commission};

    // make all symbols on path point to the same PlannedExecution
    for (const auto &tradingSymbol : tradingSymbolsList)
    {
      symbolToPlannedExecutions.insert(tradingSymbol.symbol(), execution);
    }
  }

  return Engine{symbolToPlannedExecutions, symbolToOffer};
}

double get_double_from_json(const QJsonObject &json, const QString &key)
{
  return std::stod(get_from_json(json, key).toString().toStdString());
}

QList<PlannedExecution> Engine::priceUpdate(const QJsonObject &json)
{
  QString symbol = get_from_json(json, "s").toString();
  auto askPrice = get_double_from_json(json, "a");
  auto bidPrice = get_double_from_json(json, "b");
  auto askQty = get_double_from_json(json, "A");
  auto bidQty = get_double_from_json(json, "B");

  // update existing offer for symbol
  auto &offer = mSymbolToOffer[symbol];
  offer.askPrice = askPrice;
  offer.bidPrice = bidPrice;
  offer.askQty = askQty;
  offer.bidQty = bidQty;

  // update all planned executions that use this symbol
  QList<PlannedExecution> updatedExecutions = mSymbolToPlannedExecutions.values(symbol);
  for (auto &execution : updatedExecutions)
  {
    execution.update();
  }

  // reject unprofitable
  updatedExecutions.removeIf([](const PlannedExecution &execution)
                             { return execution.totalProfit() <= 0; });

  // sort by total profit
  std::sort(updatedExecutions.begin(), updatedExecutions.end(), [](const PlannedExecution &a, const PlannedExecution &b)
            { return a.totalProfit() > b.totalProfit(); });

  return updatedExecutions;
}
