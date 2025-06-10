#pragma once

#include "PreciseNumber.h"
#include <string>

class Symbol {
public:
  Symbol() = default;

  Symbol(const std::string symbolStr, const std::string baseAsset,
         const std::string quoteAsset, const int baseAssetPrecision,
         const int quoteAssetPrecision, const PreciseNumber minNotional,
         const PreciseNumber baseAssetIncrement,
         const PreciseNumber quoteAssetIncrement);

  const std::string symbol{};
  const std::string baseAsset{};
  const std::string quoteAsset{};
  PreciseNumber bidPrice{};
  PreciseNumber askPrice{};
  PreciseNumber bidQty{};
  PreciseNumber askQty{};
  const PreciseNumber minNotional{};
  const PreciseNumber baseAssetIncrement{};
  const PreciseNumber quoteAssetIncrement{};
  const int baseAssetPrecision = 0;
  const int quoteAssetPrecision = 0;
};
