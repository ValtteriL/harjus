#include "tradingsymbol.h"

/*
      {
        "base_asset": "ETH",
        "base_asset_increment": "0.00000001",
        "base_asset_precision": 8,
        "min_notional": "1.0",
        "position": "long",
        "price": "0",
        "qty": "0",
        "quote_asset": "BTC",
        "quote_asset_increment": "0.00000001",
        "quote_asset_precision": 8,
        "symbol": "ETHBTC"
      },
*/

QJsonValue get_from_json(const QJsonObject &json, const QString &key)
{
  if (const QJsonValue v = json[key]; !v.isUndefined())
    return v;
  else
    throw std::runtime_error(key.toStdString() + " is not defined");
}

TradingSymbol TradingSymbol::fromJson(const QJsonObject &json)
{
  QString baseAsset = get_from_json(json, "base_asset").toString();
  QString quoteAsset = get_from_json(json, "quote_asset").toString();
  QString symbol = get_from_json(json, "symbol").toString();
  QString position = get_from_json(json, "position").toString();
  double price = get_from_json(json, "price").toDouble();
  double qty = get_from_json(json, "qty").toDouble();
  double baseAssetIncrement = get_from_json(json, "base_asset_increment").toDouble();
  int baseAssetPrecision = get_from_json(json, "base_asset_precision").toInt();
  double minNotional = get_from_json(json, "min_notional").toDouble();
  double quoteAssetIncrement = get_from_json(json, "quote_asset_increment").toDouble();
  int quoteAssetPrecision = get_from_json(json, "quote_asset_precision").toInt();

  Position pos = position == "long" ? Position::LONG : Position::SHORT;

  return TradingSymbol{symbol, pos, baseAsset, quoteAsset, baseAssetIncrement, baseAssetPrecision, quoteAssetIncrement, quoteAssetPrecision, minNotional};
}