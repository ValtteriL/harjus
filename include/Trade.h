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
  const Symbol symbol_;
  const Position position_;
  const boost::multiprecision::cpp_dec_float_50 &offerQty_;
  boost::multiprecision::cpp_dec_float_50 orderQty_;
  const boost::multiprecision::cpp_dec_float_50 &orderPrice_;
  const std::string recvCurrency_;
  const std::string usedCurrency_;

public:
  Trade(const Symbol &symbol, Position position)
      : symbol_(symbol), position_(position),
        offerQty_(position == Position::LONG ? symbol.askQty : symbol.bidQty),
        orderQty_(offerQty_),
        orderPrice_(position == Position::LONG ? symbol.askPrice
                                               : symbol.bidPrice),
        recvCurrency_(position == Position::LONG ? symbol.baseAsset
                                                 : symbol.quoteAsset),
        usedCurrency_(position == Position::LONG ? symbol.quoteAsset
                                                 : symbol.baseAsset) {}

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
   * Get the order price of the trade.
   * @return The price per unit of base asset.
   */
  boost::multiprecision::cpp_dec_float_50 getOrderPrice() const;

  /**
   * Get the symbol of the trade.
   * @return The symbol of the trade.
   */
  const Symbol &getSymbol() const;

  /**
   * Set the budget for the trade. Updates the order quantity and price to the
   * maximum allowed by the budget and best offers.
   * @param budget The budget (in used asset) to be set.
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
  bool operator==(const Trade &other) const {
    return getSymbol().symbol == other.getSymbol().symbol &&
           getPosition() == other.getPosition() &&
           getOrderQty() == other.getOrderQty();
  }

  /**
   * Hash function for Trade.
   * Combines the hash of the symbol and position to create a unique hash for
   * the trade. This ensures that trades with the same symbol and position are
   * treated as the same.
   */
  std::size_t hash() const {
    return std::hash<std::string>()(getSymbol().symbol) ^
           std::hash<Position>()(getPosition());
  }

}; // namespace std

// Specialization of std::hash for Trade
namespace std {
template <> struct hash<Trade> {
  std::size_t operator()(const Trade &trade) const { return trade.hash(); }
};