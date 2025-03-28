#pragma once

#include <QString>
#include <QJsonObject>
#include <QJsonArray>
#include "position.h"

class TradingSymbol
{
public:
  TradingSymbol(QString symbol, Position position, QString base_asset, QString quote_asset, long double baseAssetIncrement, int baseAssetPrecision, long double quoteAssetIncrement, int quoteAssetPrecision, long double minNotional)
      : mSymbol{symbol}, mPosition{position}, base_asset{base_asset}, quote_asset{quote_asset}, mBaseAssetIncrement{baseAssetIncrement}, mBaseAssetPrecision{baseAssetPrecision}, mQuoteAssetIncrement{quoteAssetIncrement}, mQuoteAssetPrecision{quoteAssetPrecision}, mMinNotional{minNotional} {}
  QJsonObject toJson() const;
  static TradingSymbol fromJson(const QJsonObject &json);
  long double price() const { return *mPrice; }
  long double qty() const { return mQty; }
  QString symbol() const { return mSymbol; }
  long double maxQty() const { return *mMaxQty; }
  void setPrice(long double &price) { mPrice = &price; }
  void setMaxQty(long double &qty) { mMaxQty = &qty; }
  long double setQtyUpto(long double qty);
  Position position() const { return mPosition; }
  QString usedAsset() const { return mPosition == Position::LONG ? quote_asset : base_asset; }
  long double receiveivedAmount() const { return mPosition == Position::LONG ? mQty : mQty * *mPrice; }
  long double usedAmount() const { return mPosition == Position::LONG ? mQty * *mPrice : mQty; }

private:
  QString mSymbol;
  Position mPosition;
  QString base_asset;
  QString quote_asset;
  long double mBaseAssetIncrement;
  int mBaseAssetPrecision;
  long double mQuoteAssetIncrement;
  int mQuoteAssetPrecision;
  long double mMinNotional;
  long double *mPrice = nullptr;
  long double mQty = 0;
  long double *mMaxQty = nullptr;
};

long double get_long_double_from_json(const QJsonObject &json, const QString &key);
QString get_string_from_json(const QJsonObject &json, const QString &key);
QJsonObject get_object_from_json(const QJsonObject &json, const QString &key);
QJsonArray get_array_from_json(const QJsonObject &json, const QString &key);
