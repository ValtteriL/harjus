#include "Execution.h"
#include "IExecution.h"
#include "Trade.h"
#include <vector>

/**
 * @brief Calculate the maximum quantity of the starting asset after all trades.
 * @param trades A vector of trades.
 * @param startingAssetBudget The initial budget in the starting asset.
 * @return The maximum quantity of the starting asset after all trades in the
 * execution.
 */
boost::multiprecision::cpp_dec_float_50 calculateMaxQtyAfterTrades(
    std::vector<Trade> &trades,
    boost::multiprecision::cpp_dec_float_50 startingAssetBudget) {
  auto acc = startingAssetBudget;

  for (const auto &trade : trades) {

    if (trade.getPosition() == Position::LONG) {
      acc = boost::multiprecision::min(acc, trade.getUsedQty() *
                                                trade.getOrderPrice()) /
            trade.getOrderPrice();
    } else {
      acc = boost::multiprecision::min(acc, trade.getUsedQty()) *
            trade.getOrderPrice();
    }
  }
  return acc;
}

boost::multiprecision::cpp_dec_float_50 calculateStartingAssetQty(
    std::vector<Trade> &trades,
    boost::multiprecision::cpp_dec_float_50 startingAssetQtyAfterTrades) {

  boost::multiprecision::cpp_dec_float_50 acc{startingAssetQtyAfterTrades};

  // backtrack the trades to calculate the starting asset qty
  for (auto it = trades.rbegin(); it != trades.rend(); ++it) {
    const auto &trade = *it;

    if (trade.getPosition() == Position::LONG) {
      acc *= trade.getOrderPrice();
    } else {
      acc /= trade.getOrderPrice();
    }
  }
  return acc;
}

void Execution::update(
    boost::multiprecision::cpp_dec_float_50 startingAssetBudget) {

  // calculate max qty starting asset we can have at the end of the trades
  auto maxQtyAfterTrades =
      calculateMaxQtyAfterTrades(_trades, startingAssetBudget);

  // calculate corresponding starting asset qty (AKA capacity)
  auto startingAssetQty = calculateStartingAssetQty(_trades, maxQtyAfterTrades);

  // update trades with quantities
  auto acc = startingAssetQty;
  for (auto &trade : _trades) {
    trade.setBudget(acc);
    acc = trade.getRecvQty();
  }

  // update profit
  boost::multiprecision::cpp_dec_float_50 totalCommission =
      _trades.front().getUsedQty() *
      (boost::multiprecision::pow((1 + _commission), _trades.size()) - 1);
  _totalProfit = (_trades.back().getRecvQty() - _trades.front().getUsedQty() -
                  totalCommission) *
                 _relativeValue;
}
boost::multiprecision::cpp_dec_float_50 Execution::getTotalProfit() const {
  return _totalProfit;
}

std::string Execution::getStartingAsset() const { return _startingAsset; }

boost::multiprecision::cpp_dec_float_50 Execution::getCapacity() const {
  return _trades.front().getUsedQty();
}

std::vector<Trade> &Execution::getTrades() { return _trades; }
