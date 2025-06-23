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
  Symbol const *_symbol = nullptr;
  Position _position = Position::LONG;
  PreciseNumber _orderQty{"0"};
  std::string _recvCurrency = "PLACEHOLDER";
  std::string _usedCurrency = "PLACEHOLDER";

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
  [[nodiscard]] auto position() const -> enum Position;

  /**
   * Get the order quantity of the trade.
   * @return The quantity of the base asset to be traded.
   */
  [[nodiscard]] auto orderQty() const -> PreciseNumber;

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
  [[nodiscard]] auto offerQty() const -> PreciseNumber;

  /**
   * Get the order price of the trade.
   * @return The price per unit of base asset.
   */
  [[nodiscard]] auto orderPrice() const -> PreciseNumber;

  /**
   * Get the symbol of the trade.
   * @return The symbol of the trade.
   */
  [[nodiscard]] auto symbol() const -> const Symbol *;

  /**
   * @brief Set the budget for the trade. Updates the order to the maximum
   * allowed by the budget and symbol.
   * @details Sets the maximum correct order quantity given the budget and
   * symbol. The order quantity is a multiple of the base asset increment.
   * If the maximum order quantity is less than the minimum notional, the order
   * quantity is set to 0.
   * @param budget The budget (in used asset) for the trade.
   */
  void recalculateOrderQty(const PreciseNumber &budget);

  /**
   * Get the quantity of the asset to be received.
   * @return The quantity of the asset to be received.
   */
  [[nodiscard]] auto recvQty() const -> PreciseNumber;

  /**
   * Get the quantity of the asset to be used.
   * @return The quantity of the asset to be used.
   */
  [[nodiscard]] auto usedQty() const -> PreciseNumber;

  /**
   * Get the currency of the asset to be received.
   * @return The currency of the asset to be received.
   */
  [[nodiscard]] auto recvCurrency() const -> std::string;

  /**
   * Get the currency of the asset to be used.
   * @return The currency of the asset to be used.
   */
  [[nodiscard]] auto usedCurrency() const -> std::string;

  /**
   * Compare two trades for equality. This is used to check if a trade is
   * already reserved. This ensures that trades with the same symbol and
   * position are treated as the same.
   */
  auto operator==(const Trade &other) const -> bool;

  /**
   * @brief Copy constructor for Trade class.
   * @param other The Trade object to copy from.
   */
  Trade(const Trade &other) = default;
};
