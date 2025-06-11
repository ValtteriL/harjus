#pragma once

#include "PreciseNumber.h"
#include <string>

class Symbol {
public:
  const std::string symbol{};
  const std::string baseAsset{};
  const std::string quoteAsset{};
  const PreciseNumber minNotional{};
  const PreciseNumber baseAssetIncrement{};
  const PreciseNumber quoteAssetIncrement{};
  const int baseAssetPrecision;
  const int quoteAssetPrecision;
  PreciseNumber bidPrice{};
  PreciseNumber askPrice{};
  PreciseNumber bidQty{};
  PreciseNumber askQty{};
};
