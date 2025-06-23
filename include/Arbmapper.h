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
auto getTradingPaths(const std::unordered_map<std::string, Symbol> &symbolMap,
                     const IConfiguration &configuration)
    -> std::vector<std::vector<Trade> *>;
