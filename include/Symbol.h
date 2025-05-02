#pragma once

#include <boost/multiprecision/cpp_dec_float.hpp>
#include <string>

class Symbol {
public:
  std::string symbol;
  std::string baseAsset;
  std::string quoteAsset;
  mutable boost::multiprecision::cpp_dec_float_50 bidPrice;
  mutable boost::multiprecision::cpp_dec_float_50 askPrice;
  mutable boost::multiprecision::cpp_dec_float_50 bidQty;
  mutable boost::multiprecision::cpp_dec_float_50 askQty;
  boost::multiprecision::cpp_dec_float_50 minNotional;
  boost::multiprecision::cpp_dec_float_50 baseAssetIncrement;
  boost::multiprecision::cpp_dec_float_50 quoteAssetIncrement;
  int baseAssetPrecision;
  int quoteAssetPrecision;
};
