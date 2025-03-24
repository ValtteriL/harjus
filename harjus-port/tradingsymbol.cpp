#include "tradingsymbol.h"
#include "engine.h"

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

QJsonObject TradingSymbol::toJson() const
{
  QJsonObject json;

  json["symbol"] = mSymbol;
  json["position"] = mPosition == Position::LONG ? "long" : "short";
  json["base_asset"] = base_asset;
  json["quote_asset"] = quote_asset;
  json["min_notional"] = mMinNotional;
  json["base_asset_increment"] = mBaseAssetIncrement;
  json["base_asset_precision"] = mBaseAssetPrecision;
  json["quote_asset_increment"] = mQuoteAssetIncrement;
  json["quote_asset_precision"] = mQuoteAssetPrecision;
  json["qty"] = mQty;
  json["price"] = *mPrice;

  return json;
}

TradingSymbol TradingSymbol::fromJson(const QJsonObject &json)
{
  QString baseAsset = get_from_json(json, "base_asset").toString();
  QString quoteAsset = get_from_json(json, "quote_asset").toString();
  QString symbol = get_from_json(json, "symbol").toString();
  QString position = get_from_json(json, "position").toString();
  double baseAssetIncrement = get_double_from_json(json, "base_asset_increment");
  int baseAssetPrecision = get_from_json(json, "base_asset_precision").toInt();
  double minNotional = get_double_from_json(json, "min_notional");
  double quoteAssetIncrement = get_double_from_json(json, "quote_asset_increment");
  int quoteAssetPrecision = get_from_json(json, "quote_asset_precision").toInt();

  Position pos = position == "long" ? Position::LONG : Position::SHORT;

  return TradingSymbol{symbol, pos, baseAsset, quoteAsset, baseAssetIncrement, baseAssetPrecision, quoteAssetIncrement, quoteAssetPrecision, minNotional};
}

// set mQty to the highest quantity upto to the given qty, taking into account minNotional, increments & precision
// return the actual qty set
// if set qty would not satisfy minNotional, set qty to 0
double TradingSymbol::setQtyUpto(double qty)
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
