#include <QString>

struct TradingSymbol
{
  const QString symbol;
  enum class Position
  {
    LONG,
    SHORT
  };
  const Position position;
  const QString base_asset;
  const QString quote_asset;
  const double base_asset_increment;
  const int base_asset_precision;
  const double quote_asset_increment;
  const int quote_asset_precision;
  const double min_notional;
  double qty;
  double &price;
};
