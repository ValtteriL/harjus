#include "Opportunity.h"
#include "Trade.h"
#include <vector>

Opportunity::Opportunity(std::vector<Trade> &trades,
                         PreciseNumber relativeValue, PreciseNumber commission)
    : _trades(trades), _startingAsset(trades.front().usedCurrency()),
      _commission(commission), _relativeValue(relativeValue) {}

/**
 * @brief Calculate the maximum quantity of the starting asset after all trades.
 * @param trades A vector of trades.
 * @param startingAssetBudget The initial budget in the starting asset.
 * @return The maximum quantity of the starting asset after all trades in the
 * opportunity.
 */
PreciseNumber calculateMaxQtyAfterTrades(std::vector<Trade> &trades,
                                         PreciseNumber startingAssetBudget) {
  auto acc = startingAssetBudget;

  for (auto &trade : trades) {

    // reset order qty to the offer qty
    // this is needed to avoid capping to outdated order qty
    trade.resetOrderQty();

    if (trade.position() == Position::LONG) {
      if (trade.orderPrice() == 0) {
        // avoid division by zero
        // this may happen if not all trades have been updated in the path
        return 0;
      }
      acc = PreciseNumber::min(acc,
                                       trade.usedQty() * trade.orderPrice()) /
            trade.orderPrice();
    } else {
      acc =
          PreciseNumber::min(acc, trade.usedQty()) * trade.orderPrice();
    }
  }
  return acc;
}

PreciseNumber
calculateStartingAssetQty(std::vector<Trade> &trades,
                          PreciseNumber startingAssetQtyAfterTrades) {

  PreciseNumber acc{startingAssetQtyAfterTrades};

  // backtrack the trades to calculate the starting asset qty
  for (auto it = trades.rbegin(); it != trades.rend(); ++it) {
    const auto &trade = *it;

    if (trade.position() == Position::LONG) {
      acc *= trade.orderPrice();
    } else {

      if (trade.orderPrice() == 0) {
        // avoid division by zero
        // this may happen if not all trades have been updated in the path
        return 0;
      }

      acc /= trade.orderPrice();
    }
  }
  return acc;
}

void Opportunity::update(PreciseNumber startingAssetBudget) {

  // calculate max qty starting asset we can have at the end of the trades
  auto maxQtyAfterTrades =
      calculateMaxQtyAfterTrades(_trades, startingAssetBudget);

  // calculate corresponding starting asset qty (AKA capacity)
  auto startingAssetQty = calculateStartingAssetQty(_trades, maxQtyAfterTrades);

  // update trades with quantities
  auto acc = startingAssetQty;
  for (auto &trade : _trades) {
    trade.recalculateOrderQty(acc);
    acc = trade.recvQty();
  }

  // update profit
  PreciseNumber totalCommission =
      _trades.front().usedQty() *
      (PreciseNumber::pow((PreciseNumber{1} + _commission), _trades.size()) - 1);
  _totalProfit =
      (_trades.back().recvQty() - _trades.front().usedQty() - totalCommission) *
      _relativeValue;
}
PreciseNumber Opportunity::getTotalProfit() const { return _totalProfit; }

std::string Opportunity::getStartingAsset() const { return _startingAsset; }

PreciseNumber Opportunity::getCapacity() const {
  return _trades.front().usedQty();
}

std::vector<Trade> &Opportunity::getTrades() { return _trades; }
