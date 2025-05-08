#pragma once

#include "Position.h"
#include "Symbol.h"
#include <boost/multiprecision/cpp_dec_float.hpp>
#include <string>

/**
 * Trade class representing a trade in the system.
 */
class Trade {

private:
  const Symbol *_symbol;
  Position _position;
  boost::multiprecision::cpp_dec_float_50 _orderQty;
  std::string _recvCurrency;
  std::string _usedCurrency;

public:
  /**
   * Constructor for the Trade class.
   * @param symbol The symbol of the trade.
   * @param position The position of the trade (LONG or SHORT).
   */
  Trade(const Symbol *symbol, Position position);

  /**
   * Get the position of the trade.
   * @return The position of the trade.
   */
  enum Position getPosition() const;

  /**
   * Get the order quantity of the trade.
   * @return The quantity of the base asset to be traded.
   */
  boost::multiprecision::cpp_dec_float_50 getOrderQty() const;

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
  boost::multiprecision::cpp_dec_float_50 getOfferQty() const;

  /**
   * Get the order price of the trade.
   * @return The price per unit of base asset.
   */
  boost::multiprecision::cpp_dec_float_50 getOrderPrice() const;

  /**
   * Get the symbol of the trade.
   * @return The symbol of the trade.
   */
  const Symbol *getSymbol() const;

  /**
   * @brief Set the budget for the trade. Updates the order to the maximum
   * allowed by the budget and symbol.
   * @details Sets the maximum correct order quantity given the budget and
   * symbol. The order quantity is a multiple of the base asset increment.
   * If the maximum order quantity is less than the minimum notional, the order
   * quantity is set to 0.
   * @param budget The budget (in used asset) for the trade.
   */
  void setBudget(boost::multiprecision::cpp_dec_float_50 budget);

  /**
   * Get the quantity of the asset to be received.
   * @return The quantity of the asset to be received.
   */
  boost::multiprecision::cpp_dec_float_50 getRecvQty() const;

  /**
   * Get the quantity of the asset to be used.
   * @return The quantity of the asset to be used.
   */
  boost::multiprecision::cpp_dec_float_50 getUsedQty() const;

  /**
   * Get the currency of the asset to be received.
   * @return The currency of the asset to be received.
   */
  std::string getRecvCurrency() const;

  /**
   * Get the currency of the asset to be used.
   * @return The currency of the asset to be used.
   */
  std::string getUsedCurrency() const;

  /**
   * Compare two trades for equality. This is used to check if a trade is
   * already reserved. This ensures that trades with the same symbol and
   * position are treated as the same.
   */
  bool operator==(const Trade &other) const;

  /**
   * Hash function for Trade.
   * Combines the hash of the symbol and position to create a unique hash for
   * the trade. This ensures that trades with the same symbol and position are
   * treated as the same.
   */
  std::size_t hash() const;

  /**
   * @brief Copy assignment operator for Trade class.
   * @param other The Trade object to copy from.
   * @return A reference to this Trade object.
   */
  Trade &operator=(const Trade &other) {
    if (this != &other) {
      _symbol = other._symbol;
      _position = other._position;
      _orderQty = other._orderQty;
      _recvCurrency = other._recvCurrency;
      _usedCurrency = other._usedCurrency;
    }
    return *this;
  };

  /**
   * @brief Copy constructor for Trade class.
   * @param other The Trade object to copy from.
   */
  Trade(const Trade &other) = default;
};

// Specialization of std::hash for Trade
namespace std {
template <> struct hash<Trade> {
  std::size_t operator()(const Trade &trade) const { return trade.hash(); }
};
} // namespace std