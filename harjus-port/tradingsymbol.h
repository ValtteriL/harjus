#include <QString>
#include <QJsonObject>
#include "position.h"

class TradingSymbol
{
public:
  QJsonObject toJson() const;
  double price() const { return mPrice; }
  double qty() const { return mQty; }
  double maxQty() const { return mMaxQty; }
  double setQtyUpto(double qty); // TODO: take into account minNotional, increments, precisions. Return the actual qty set.
  Position position() const { return mPosition; }

private:
  const QString symbol;
  const Position mPosition;
  const QString base_asset;
  const QString quote_asset;
  const double mBaseAssetIncrement;
  const int mBaseAssetPrecision;
  const double mQuoteAssetIncrement;
  const int mQuoteAssetPrecision;
  const double mMinNotional;
  double &mPrice;
  double mQty;
  double &mMaxQty;
};
