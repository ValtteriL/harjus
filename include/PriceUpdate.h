#pragma once

#include <boost/multiprecision/cpp_dec_float.hpp>
#include <ostream>
#include <string>

/**
 * @file PriceUpdate.h
 * @brief Struct for price updates from the exchange
 * @details A price update is a message from the exchange that contains the
 * latest prices and quantities (bid+ask) for a specific symbol.
 */
struct PriceUpdate {
  std::string symbol;
  boost::multiprecision::cpp_dec_float_50 bidPrice;
  boost::multiprecision::cpp_dec_float_50 askPrice;
  boost::multiprecision::cpp_dec_float_50 bidQty;
  boost::multiprecision::cpp_dec_float_50 askQty;
};

/**
 * @brief Stream operator overload for PriceUpdate
 * @param os Output stream
 * @param update PriceUpdate to print
 * @return Reference to the output stream
 */
std::ostream &operator<<(std::ostream &os, const PriceUpdate &update);
