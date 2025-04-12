#pragma once

#include "Balance.h"
#include "IConfiguration.h"
#include "Symbol.h"
#include <unordered_map>
#include <boost/multiprecision/cpp_dec_float.hpp>

Balance getBalance(IConfiguration &config);
std::unordered_map<std::string, Symbol> getSymbols(IConfiguration &config);
std::unordered_map<std::string, boost::multiprecision::cpp_dec_float_50> getRelativeValues(IConfiguration &config, const std::unordered_map<std::string, Symbol> &symbols);
