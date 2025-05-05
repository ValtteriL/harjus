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
  return _trades.front().getUsedQty();
}

void Execution::update(boost::multiprecision::cpp_dec_float_50) {}