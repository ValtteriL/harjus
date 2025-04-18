#pragma once

#include <string>
#include <boost/multiprecision/cpp_dec_float.hpp>
#include "Position.h"

class Symbol
{
public:
  std::string symbol;
  std::string baseAsset;
  std::string quoteAsset;
  boost::multiprecision::cpp_dec_float_50 bidPrice;
  boost::multiprecision::cpp_dec_float_50 askPrice;
  boost::multiprecision::cpp_dec_float_50 bidQty;
  boost::multiprecision::cpp_dec_float_50 askQty;
  boost::multiprecision::cpp_dec_float_50 minNotional;
  boost::multiprecision::cpp_dec_float_50 baseAssetIncrement;
  boost::multiprecision::cpp_dec_float_50 quoteAssetIncrement;
  int baseAssetPrecision;
  int quoteAssetPrecision;
};
