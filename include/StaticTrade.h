#pragma once

#include "Position.h"
#include "PreciseNumber.h"
#include "Trade.h"
#include <string>

/**
 * Trade class representing a trade in the system.
 */
class StaticTrade {

private:
  std::string _symbol;
  Position _position;
  PreciseNumber _orderQty;
  PreciseNumber _orderPrice;
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
  PreciseNumber orderQty() const;

  /**
   * Get the order price of the trade.
   * @return The price per unit of base asset.
   */
  PreciseNumber orderPrice() const;

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
   * Equality operator for StaticTrade
   */
  bool operator==(const StaticTrade &other) const;
};
