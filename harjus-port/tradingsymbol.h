#pragma once

#include <QString>
#include <QJsonObject>
#include "position.h"

class TradingSymbol
{
public:
  TradingSymbol(QString symbol, Position position, QString base_asset, QString quote_asset, double baseAssetIncrement, int baseAssetPrecision, double quoteAssetIncrement, int quoteAssetPrecision, double minNotional)
      : mSymbol(symbol), mPosition(position), base_asset(base_asset), quote_asset(quote_asset), mBaseAssetIncrement(baseAssetIncrement), mBaseAssetPrecision(baseAssetPrecision), mQuoteAssetIncrement(quoteAssetIncrement), mQuoteAssetPrecision(quoteAssetPrecision), mMinNotional(minNotional) {}
  QJsonObject toJson() const;
  static TradingSymbol fromJson(const QJsonObject &json);
  double price() const { return *mPrice; }
  double qty() const { return mQty; }
  QString symbol() const { return mSymbol; }
  double maxQty() const { return *mMaxQty; }
  void setPrice(double &price) { mPrice = &price; }
  void setMaxQty(double &qty) { mMaxQty = &qty; }
  double setQtyUpto(double qty); // TODO: take into account minNotional, increments, precisions. Return the actual qty set.
  Position position() const { return mPosition; }
  QString usedAsset() const { return mPosition == Position::LONG ? quote_asset : base_asset; }

private:
  QString mSymbol;
  Position mPosition;
  QString base_asset;
  QString quote_asset;
  double mBaseAssetIncrement;
  int mBaseAssetPrecision;
  double mQuoteAssetIncrement;
  int mQuoteAssetPrecision;
  double mMinNotional;
  double *mPrice = nullptr;
  double mQty = 0;
  double *mMaxQty = nullptr;
};

QJsonValue get_from_json(const QJsonObject &json, const QString &key);