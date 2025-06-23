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

auto Execution::getTotalProfit() const -> PreciseNumber { return _totalProfit; }

auto Execution::getStartingAsset() const -> std::string { return _startingAsset; }
std::queue<StaticTrade> Execution::getTrades() const { return _trades; }

auto Execution::getCapacity() const -> PreciseNumber { return _capacity; }

void Execution::update(const PreciseNumber&) {}

/**
 * @brief Stream operator overload for Execution
 * @param os Output stream
 * @param execution Execution object to print
 * @return Reference to the output stream
 */
auto operator<<(std::ostream &os, const Execution &execution) -> std::ostream & {
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