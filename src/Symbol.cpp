#include "Symbol.h"

Symbol::Symbol(const std::string symbolStr, const std::string baseAsset,
               const std::string quoteAsset, const int baseAssetPrecision,
               const int quoteAssetPrecision, const PreciseNumber minNotional,
               const PreciseNumber baseAssetIncrement,
               const PreciseNumber quoteAssetIncrement)
    : symbol(symbolStr), baseAsset(baseAsset), quoteAsset(quoteAsset),
      minNotional(minNotional), baseAssetIncrement(baseAssetIncrement),
      quoteAssetIncrement(quoteAssetIncrement),
      baseAssetPrecision(baseAssetPrecision),
      quoteAssetPrecision(quoteAssetPrecision) {};