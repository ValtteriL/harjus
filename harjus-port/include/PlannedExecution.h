#pragma once

#include <QJsonObject>
#include "ITrade.h"

/**
 *  Planned Execution class. Contains all information requried to execute arbitrage opportunity.
 */

class PlannedExecution
{
public:
  /**
   *  Get total profit. In relatie price, given last update's calculations.
   */
  long double totalProfit() const { return mTotalProfit; }

  /**
   *  Update execution plan with current offer information. Calculate total profit, and optimal quantities for trades.
   */
  void update();

  /**
   *  Convert to JSON. Convers execution plan to JSON object.
   */
  QJsonObject toJson() const;

  /**
   *  Constructor. Create a new planned execution with given trades, relative price and commission.
   */
  PlannedExecution(std::vector<ITrade> trades, long double relativePrice, long double commission) : mTrades{trades}, mTotalProfit{0}, mRelativePrice(relativePrice), mCommission(commission) {};

  /**
   * Trades. Get all trades in this execution plan.
   */
  std::vector<ITrade> mTrades;

  /**
   * Total profit. Total profit in relative price.
   */
  long double mTotalProfit;

  /**
   * Relative price. Relative price of the asset this execution increments.
   */
  long double mRelativePrice;

  /**
   * Commission. Commission rate for this execution.
   */
  long double mCommission;
};