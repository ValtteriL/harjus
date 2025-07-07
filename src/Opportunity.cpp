#include "Opportunity.h"
#include "PreciseNumber.h"
#include "Trade.h"
#include <boost/log/core.hpp>
#include <boost/log/expressions.hpp>
#include <boost/log/trivial.hpp>
#include <string>
#include <vector>

Opportunity::Opportunity(std::vector<Trade> &trades,
                         const PreciseNumber &relativeValue,
                         const PreciseNumber &commission)
    : _trades(&trades), _startingAsset(trades.front().usedCurrency()),
      _commission(commission), _relativeValue(relativeValue) {}

/**
 * @brief Calculate the maximum quantity of the starting asset after all trades.
 * @param trades A vector of trades.
 * @param startingAssetBudget The initial budget in the starting asset.
 * @return The maximum quantity of the starting asset after all trades in the
 * opportunity.
 */
auto calculateMaxQtyAfterTrades(std::vector<Trade> *trades,
                                const PreciseNumber &startingAssetBudget)
    -> PreciseNumber {
  PreciseNumber acc{startingAssetBudget};

  for (auto &trade : *trades) {

    // reset order qty to the offer qty
    // this is needed to avoid capping to outdated order qty
    trade.resetOrderQty();

    if (trade.position() == Position::LONG) {
      if (trade.orderPrice() == PreciseNumber{"0"}) {
        // avoid division by zero
        // this may happen if not all trades have been updated in the path
        return PreciseNumber{};
      }
      acc = PreciseNumber::min(acc, trade.usedQty() * trade.orderPrice()) /
            trade.orderPrice();
    } else {
      acc = PreciseNumber::min(acc, trade.usedQty()) * trade.orderPrice();
    }
  }
  return acc;
}

auto calculateStartingAssetQty(std::vector<Trade> *trades,
                               PreciseNumber const &startingAssetQtyAfterTrades)
    -> PreciseNumber {

  PreciseNumber acc{startingAssetQtyAfterTrades};

  // backtrack the trades to calculate the starting asset qty
  for (auto it = trades->rbegin(); it != trades->rend(); ++it) {
    const auto &trade = *it;

    if (trade.position() == Position::LONG) {
      acc *= trade.orderPrice();
    } else {

      if (trade.orderPrice() == PreciseNumber{"0"}) {
        // avoid division by zero
        // this may happen if not all trades have been updated in the path
        return PreciseNumber{};
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
  for (auto &trade : *_trades) {
    trade.recalculateOrderQty(acc);
    acc = trade.recvQty();
  }

  // update profit
  auto recvQty = _trades->back().recvQty();
  auto usedQty = _trades->front().usedQty();
  _totalProfit =
      (recvQty *
           (PreciseNumber{"1"} -
            _commission * PreciseNumber{std::to_string(_trades->size())}) -
       usedQty) *
      _relativeValue;
}
auto Opportunity::getTotalProfit() const -> PreciseNumber {
  return _totalProfit;
}

auto Opportunity::getStartingAsset() const -> std::string {
  return _startingAsset;
}

auto Opportunity::getCapacity() const -> PreciseNumber {
  return _trades->front().usedQty();
}

auto Opportunity::getTrades() const -> std::vector<Trade> { return *_trades; }
