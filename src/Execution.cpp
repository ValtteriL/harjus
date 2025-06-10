#include "Execution.h"
#include "StaticTrade.h"

Execution::Execution(Opportunity &opportunity)
    : _startingAsset(opportunity.getStartingAsset()),
      _totalProfit(opportunity.getTotalProfit()),
      _capacity(opportunity.getCapacity()) {

  // insert trades into the vector
  _tradesVector.reserve(opportunity.getTrades().size());
  for (const auto &trade : opportunity.getTrades()) {
    _tradesVector.push_back(StaticTrade(trade));
  }

  for (const auto &trade : opportunity.getTrades()) {
    _trades.push(trade);
  }
}

PreciseNumber Execution::getTotalProfit() const { return _totalProfit; }

std::string Execution::getStartingAsset() const { return _startingAsset; }
std::queue<StaticTrade> Execution::getTrades() const { return _trades; }

PreciseNumber Execution::getCapacity() const { return _capacity; }

void Execution::update(PreciseNumber) {}

/**
 * @brief Stream operator overload for Execution
 * @param os Output stream
 * @param execution Execution object to print
 * @return Reference to the output stream
 */
std::ostream &operator<<(std::ostream &os, const Execution &execution) {
  os << "Execution{"
     << "startingAsset='" << execution._startingAsset << "', "
     << "totalProfit=" << execution._totalProfit << " BTC, "
     << "capacity=" << execution.getCapacity() << ", "
     << "symbols=[";

  // Add the symbols of all trades
  bool first = true;
  for (const auto &trade : execution._tradesVector) {
    if (!first) {
      os << ", ";
    }
    os << "'" << trade.symbol() << "'";
    first = false;
  }

  os << "]}";
  return os;
}