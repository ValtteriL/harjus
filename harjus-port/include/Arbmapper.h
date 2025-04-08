#pragma once

#include <vector>
#include "Symbol.h"

std::vector<std::vector<Symbol>> getTradingPaths(std::vector<Symbol> &symbols, int maxDepth, std::vector<Symbol> &skipSymbols);
