#pragma once

#include "PreciseNumber.h"
#include <string>

class Symbol {
public:
  std::string symbol;
  std::string baseAsset;
  std::string quoteAsset;
  PreciseNumber bidPrice;
  PreciseNumber askPrice;
  PreciseNumber bidQty;
  PreciseNumber askQty;
  PreciseNumber minNotional;
  PreciseNumber baseAssetIncrement;
  PreciseNumber quoteAssetIncrement;
  int baseAssetPrecision;
  int quoteAssetPrecision;
};
