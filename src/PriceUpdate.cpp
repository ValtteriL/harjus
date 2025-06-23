#include "PriceUpdate.h"

/**
 * @brief Stream operator overload for PriceUpdate
 * @param os Output stream
 * @param update PriceUpdate to print
 * @return Reference to the output stream
 */
auto operator<<(std::ostream &os, const PriceUpdate &update) -> std::ostream & {
  os << "PriceUpdate{"
     << "symbol='" << update.symbol << "', "
     << "bid=" << update.bidPrice << "@" << update.bidQty << ", "
     << "ask=" << update.askPrice << "@" << update.askQty << "}";
  return os;
}