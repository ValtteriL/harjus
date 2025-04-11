#pragma once

#include "Balance.h"
#include "IConfiguration.h"
#include "Symbol.h"
#include <unordered_map>

Balance getBalance(IConfiguration &config);
std::unordered_map<std::string, Symbol> getSymbols(IConfiguration &config);
