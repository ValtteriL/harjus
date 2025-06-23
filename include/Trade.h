#pragma once

#include "Position.h"
#include "PreciseNumber.h"
#include "Symbol.h"
#include <string>

/**
 * Trade class representing a trade in the system.
 */
class Trade {

private:
  const Symbol *_symbol = nullptr;
  const Position _position = Position::LONG;
  PreciseNumber _orderQty{"0"};
  const std::string _recvCurrency = "PLACEHOLDER";
  const std::string _usedCurrency = "PLACEHOLDER";

public:
  /**
   * Default constructor for the Trade class.
   * @details This constructor is used to create a trade with default values.
   */
  Trade() = default;

  /**
   * Constructor for the Trade class.
   * @param symbol The symbol of the trade.
   * @param position The position of the trade (LONG or SHORT).
   */
  Trade(const Symbol *symbol, const Position position);

  /**
   * Get the position of the trade.
   * @return The position of the trade.
   */
  enum Position position() const;

  /**
   * Get the order quantity of the trade.
   * @return The quantity of the base asset to be traded.
   */
  PreciseNumber orderQty() const;

  /**
   * Reset the order quantity of the trade.
   * @details This function is used to reset the order quantity to the
   * available offer quantity. It is used when the trade is not reserved.
   */
  void resetOrderQty();

  /**
   * Get the offer quantity of the trade.
   * @return The quantity of the base asset available for trading.
   */
  PreciseNumber offerQty() const;

  /**
   * Get the order price of the trade.
   * @return The price per unit of base asset.
   */
  PreciseNumber orderPrice() const;

  /**
   * Get the symbol of the trade.
   * @return The symbol of the trade.
   */
  const Symbol *symbol() const;

  /**
   * @brief Set the budget for the trade. Updates the order to the maximum
   * allowed by the budget and symbol.
   * @details Sets the maximum correct order quantity given the budget and
   * symbol. The order quantity is a multiple of the base asset increment.
   * If the maximum order quantity is less than the minimum notional, the order
   * quantity is set to 0.
   * @param budget The budget (in used asset) for the trade.
   */
  void recalculateOrderQty(const PreciseNumber& budget);

  /**
   * Get the quantity of the asset to be received.
   * @return The quantity of the asset to be received.
   */
  PreciseNumber recvQty() const;

  /**
   * Get the quantity of the asset to be used.
   * @return The quantity of the asset to be used.
   */
  PreciseNumber usedQty() const;

  /**
   * Get the currency of the asset to be received.
   * @return The currency of the asset to be received.
   */
  std::string recvCurrency() const;

  /**
   * Get the currency of the asset to be used.
   * @return The currency of the asset to be used.
   */
  std::string usedCurrency() const;

  /**
   * Compare two trades for equality. This is used to check if a trade is
   * already reserved. This ensures that trades with the same symbol and
   * position are treated as the same.
   */
  bool operator==(const Trade &other) const;

  /**
   * @brief Copy constructor for Trade class.
   * @param other The Trade object to copy from.
   */
  Trade(const Trade &other) = default;
};
