#include "Execution.h"

Execution::Execution(Opportunity &opportunity)
    : _trades(opportunity.getTrades()),
      _startingAsset(opportunity.getStartingAsset()),
      _totalProfit(opportunity.getTotalProfit()) {}

boost::multiprecision::cpp_dec_float_50 Execution::getTotalProfit() const {
  return _totalProfit;
}

std::string Execution::getStartingAsset() const { return _startingAsset; }
std::vector<Trade> &Execution::getTrades() { return _trades; }

boost::multiprecision::cpp_dec_float_50 Execution::getCapacity() const {
  return _trades.front().getOrderQty();
}

void Execution::update(boost::multiprecision::cpp_dec_float_50) {}