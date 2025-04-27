#include "Execution.h"
#include "ITrade.h"

void Execution::update() {
  // TODO: Implement the update logic
}

boost::multiprecision::cpp_dec_float_50 Execution::getTotalProfit() const {
  return _totalProfit;
}

std::string Execution::getStartingAsset() const { return _startingAsset; }
