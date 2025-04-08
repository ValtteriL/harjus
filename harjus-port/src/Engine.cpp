#include "Engine.h"
#include "Symbol.h"
#include "PlannedExecution.h"
#include <string.h>

Engine Engine::fromJson(const QJsonObject &json)
{
  // get values from json
  long double commission = get_long_double_from_json(json, "commission");
  QJsonObject relativeAssetValues = get_object_from_json(json, "relative_asset_values");
  QJsonArray tradingPaths = get_array_from_json(json, "trading_paths");

  // Convert relativeAssetValues to a QHash<QString, long double>
  QHash<QString, long double> relativePrices;
  for (const auto &key : relativeAssetValues.keys())
  {
    relativePrices[key] = std::stold(relativeAssetValues[key].toString().toStdString());
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

      long double &priceReference = ts.position() == Position::LONG ? symbolToOffer[symbol].askPrice : symbolToOffer[symbol].bidPrice;
      long double &maxQtyReference = ts.position() == Position::LONG ? symbolToOffer[symbol].askQty : symbolToOffer[symbol].bidQty;

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

QList<PlannedExecution> Engine::priceUpdate(const QJsonObject &json)
{
  QString symbol = get_string_from_json(json, "s");
  auto askPrice = get_long_double_from_json(json, "a");
  auto bidPrice = get_long_double_from_json(json, "b");
  auto askQty = get_long_double_from_json(json, "A");
  auto bidQty = get_long_double_from_json(json, "B");

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
