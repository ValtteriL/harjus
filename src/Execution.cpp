#include "Execution.h"

Execution::Execution(Opportunity &opportunity)
    : _tradesVector(opportunity.getTrades()),
      _startingAsset(opportunity.getStartingAsset()),
      _totalProfit(opportunity.getTotalProfit()) {

  for (const auto &trade : opportunity.getTrades()) {
    _trades.push(trade);
  }
}

boost::multiprecision::cpp_dec_float_50 Execution::getTotalProfit() const {
  return _totalProfit;
}

std::string Execution::getStartingAsset() const { return _startingAsset; }
std::queue<Trade> &Execution::getTrades() { return _trades; }

boost::multiprecision::cpp_dec_float_50 Execution::getCapacity() const {
  return _tradesVector.front().getUsedQty();
}

void Execution::update(boost::multiprecision::cpp_dec_float_50) {}

/**
 * @brief Stream operator overload for Execution
 * @param os Output stream
 * @param execution Execution object to print
 * @return Reference to the output stream
 */
std::ostream &operator<<(std::ostream &os, const Execution &execution) {
  os << "Execution{"
     << "startingAsset='" << execution._startingAsset << "', "
     << "totalProfit=" << execution._totalProfit << ", "
     << "capacity=" << execution.getCapacity() << ", "
     << "symbols=[";

  // Add the symbols of all trades
  bool first = true;
  for (const auto &trade : execution._tradesVector) {
    if (!first) {
      os << ", ";
    }
    os << "'" << trade.getSymbol().symbol << "'";
    first = false;
  }

  os << "]}";
  return os;
}