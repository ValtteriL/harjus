#pragma once

#include "Position.h"
#include "Symbol.h"
#include "Trade.h"
#include <boost/multiprecision/cpp_dec_float.hpp>
#include <string>

/**
 * Trade class representing a trade in the system.
 */
class StaticTrade {

private:
  std::string _symbol;
  Position _position;
  boost::multiprecision::cpp_dec_float_50 _orderQty;
  boost::multiprecision::cpp_dec_float_50 _orderPrice;
  std::string _recvCurrency;
  std::string _usedCurrency;

public:
  /**
   * Constructor for the StaticTrade class.
   * @param trade The trade object to be converted to StaticTrade.
   * @note This constructor is used to create a StaticTrade object from a Trade
   * object. It freezes the data in Trade object to be used in a trade.
   * @note The StaticTrade class is designed to be immutable, so the data
   * members are initialized in the constructor and cannot be modified later.
   */
  StaticTrade(const Trade &trade);

  /**
   * Get the symbol of the trade.
   * @return The symbol of the trade.
   */
  const std::string symbol() const;

  /**
   * Get the position of the trade.
   * @return The position of the trade.
   */
  enum Position position() const;

  /**
   * Get the order quantity of the trade.
   * @return The quantity of the base asset to be traded.
   */
  boost::multiprecision::cpp_dec_float_50 orderQty() const;

  /**
   * Get the order price of the trade.
   * @return The price per unit of base asset.
   */
  boost::multiprecision::cpp_dec_float_50 orderPrice() const;

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
   * Hash function for Trade.
   * Combines the hash of the symbol and position to create a unique hash for
   * the trade. This ensures that trades with the same symbol and position are
   * treated as the same. Need to equal the has of corresponding trade. Required
   * for the unordered_set in ReservedTrades.
   */
  std::size_t hash() const;
};

// Specialization of std::hash for StaticTrade
namespace std {
template <> struct hash<StaticTrade> {
  std::size_t operator()(const Trade &trade) const { return trade.hash(); }
};
} // namespace std