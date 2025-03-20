#include "engine.h"

Engine Engine::fromJson(const QJsonObject &json)
{
  double commission;
  QJsonObject relativeAssetValues;
  QJsonArray tradingPaths;

  // get values from json
  if (const QJsonValue v = json["commission"]; v.isDouble())
    commission = v.toDouble();
  else
    throw std::runtime_error("commission is not a double");

  if (const QJsonValue v = json["relative_asset_values"]; v.isObject())
    relativeAssetValues = v.toObject();
  else
    throw std::runtime_error("relative_asset_values is not an object");

  if (const QJsonValue v = json["trading_paths"]; v.isArray())
    tradingPaths = v.toArray();
  else
    throw std::runtime_error("trading_paths is not an array");

  // Convert relativeAssetValues to a QHash<QString, double>
  QHash<QString, double> relativePrices;
  for (const auto &key : relativeAssetValues.keys())
  {
    relativePrices[key] = relativeAssetValues[key].toDouble();
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
    QList<TradingSymbol> tradingSymbolsList;
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

      tradingSymbolsList.append(ts);
    }

    // create PlannedExecution
    auto usedAsset = tradingSymbolsList.first().usedAsset();
    PlannedExecution execution{tradingSymbolsList, relativePrices[usedAsset], commission};

    // make all symbols on path point to the same PlannedExecution
    for (const auto &tradingSymbol : tradingSymbolsList)
    {
      symbolToPlannedExecutions.insert(tradingSymbol.symbol(), execution);
    }
  }

  return Engine{symbolToPlannedExecutions, symbolToOffer};
}