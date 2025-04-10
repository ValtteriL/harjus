#pragma once

#include <vector>
#include "Symbol.h"
#include "Trade.h"

/**
 * @brief Get trading paths.
 * Given a map of , find all possible trading paths within a maximum depth.
 * The function will skip any paths starting with symbols that are in the skipSymbols vector.
 */
std::vector<std::vector<Trade>> getTradingPaths(std::unordered_map<std::string, Symbol> *symbolMap, int maxDepth, std::vector<std::string> &skipSymbols);
