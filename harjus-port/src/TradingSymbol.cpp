#include "TradingSymbol.h"
#include <string.h>

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

int get_int_from_json(const QJsonObject &json, const QString &key)
{
  return get_from_json(json, key).toInt();
}

QString get_string_from_json(const QJsonObject &json, const QString &key)
{
  return get_from_json(json, key).toString();
}

long double get_long_double_from_json(const QJsonObject &json, const QString &key)
{
  return std::stold(get_from_json(json, key).toString().toStdString());
}

QJsonObject get_object_from_json(const QJsonObject &json, const QString &key)
{
  return get_from_json(json, key).toObject();
}

QJsonArray get_array_from_json(const QJsonObject &json, const QString &key)
{
  return get_from_json(json, key).toArray();
}

QJsonObject TradingSymbol::toJson() const
{
  QJsonObject json;

  json["symbol"] = mSymbol;
  json["position"] = mPosition == Position::LONG ? "long" : "short";
  json["base_asset"] = base_asset;
  json["quote_asset"] = quote_asset;
  json["min_notional"] = QString::number(mMinNotional, 'f', 16);
  json["base_asset_increment"] = QString::number(mBaseAssetIncrement, 'f', 16);
  json["base_asset_precision"] = mBaseAssetPrecision;
  json["quote_asset_increment"] = QString::number(mQuoteAssetIncrement, 'f', 16);
  json["quote_asset_precision"] = mQuoteAssetPrecision;
  json["qty"] = QString::number(mQty, 'f', 16);
  json["price"] = QString::number(*mPrice, 'f', 16);

  return json;
}

TradingSymbol TradingSymbol::fromJson(const QJsonObject &json)
{
  QString baseAsset = get_string_from_json(json, "base_asset");
  QString quoteAsset = get_string_from_json(json, "quote_asset");
  QString symbol = get_string_from_json(json, "symbol");
  QString position = get_string_from_json(json, "position");
  long double baseAssetIncrement = get_long_double_from_json(json, "base_asset_increment");
  int baseAssetPrecision = get_int_from_json(json, "base_asset_precision");
  long double minNotional = get_long_double_from_json(json, "min_notional");
  long double quoteAssetIncrement = get_long_double_from_json(json, "quote_asset_increment");
  int quoteAssetPrecision = get_int_from_json(json, "quote_asset_precision");

  Position pos = position == "long" ? Position::LONG : Position::SHORT;

  return TradingSymbol{symbol, pos, baseAsset, quoteAsset, baseAssetIncrement, baseAssetPrecision, quoteAssetIncrement, quoteAssetPrecision, minNotional};
}

// set mQty to the highest quantity upto to the given qty, taking into account minNotional, increments & precision
// return the actual qty set
// if set qty would not satisfy minNotional, set qty to 0
long double TradingSymbol::setQtyUpto(long double qty)
{
  auto maxQty = std::min(*mMaxQty, qty);

  // make maxQty a multiple of baseAssetIncrement
  maxQty = std::floor(maxQty / mBaseAssetIncrement) * mBaseAssetIncrement;

  // if minNotional is not satisfied, maxQty = 0
  if (mPosition == Position::LONG && maxQty < mMinNotional)
  {
    maxQty = 0;
  }
  else if (mPosition == Position::SHORT && maxQty * *mPrice < mMinNotional)
  {
    maxQty = 0;
  }

  mQty = maxQty;
  return mQty;
}
