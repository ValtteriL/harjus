#pragma once

#include "PreciseNumber.h"
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
  PreciseNumber bidPrice;
  PreciseNumber askPrice;
  PreciseNumber bidQty;
  PreciseNumber askQty;
};

/**
 * @brief Stream operator overload for PriceUpdate
 * @param os Output stream
 * @param update PriceUpdate to print
 * @return Reference to the output stream
 */
std::ostream &operator<<(std::ostream &os, const PriceUpdate &update);
