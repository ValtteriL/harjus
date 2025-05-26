#pragma once

#include "IConfiguration.h"
#include "Symbol.h"
#include "Trade.h"
#include <vector>

/**
 * @brief Get trading paths.
 * Given a map of , find all possible trading paths within a maximum depth.
 * The function will skip any paths starting with symbols that are in the
 * skipSymbols vector.
 */
std::vector<std::vector<Trade> *>
getTradingPaths(std::unordered_map<std::string, Symbol *> *symbolMap,
                const IConfiguration &configuration);
