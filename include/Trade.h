#pragma once

#include "ITrade.h"
#include <string>

/**
 * Trade class representing a trade in the system.
 */
class Trade : ITrade
{
public:
  Trade(const Symbol &symbol, Position position)
      : symbol_(symbol),
        position_(position),
        offerQty_(position == Position::LONG ? symbol.askQty : symbol.bidQty),
        orderPrice_(position == Position::LONG ? symbol.askPrice : symbol.bidPrice),
        recvCurrency_(position == Position::LONG ? symbol.baseAsset : symbol.quoteAsset),
        usedCurrency_(position == Position::LONG ? symbol.quoteAsset : symbol.baseAsset) {}

  /**
   * Get the position of the trade.
   * @return The position of the trade.
   */
  enum Position getPosition() const override;

  /**
   * Get the order quantity of the trade.
   * @return The quantity of the base asset to be traded.
   */
  boost::multiprecision::cpp_dec_float_50 getOrderQty() const override;

  /**
   * Get the order price of the trade.
   * @return The price per unit of base asset.
   */
  boost::multiprecision::cpp_dec_float_50 getOrderPrice() const override;

  /**
   * Get the symbol of the trade.
   * @return The symbol of the trade.
   */
  const Symbol &getSymbol() const override;

  /**
   * Set the budget for the trade. Updates the order quantity and price to the maximum allowed by the budget and best offers.
   * @param budget The budget (in used asset) to be set.
   */
  void setBudget(boost::multiprecision::cpp_dec_float_50 budget) override;

  /**
   * Get the quantity of the asset to be received.
   * @return The quantity of the asset to be received.
   */
  boost::multiprecision::cpp_dec_float_50 getRecvQty() const override;

  /**
   * Get the quantity of the asset to be used.
   * @return The quantity of the asset to be used.
   */
  boost::multiprecision::cpp_dec_float_50 getUsedQty() const override;

  /**
   * Get the currency of the asset to be received.
   * @return The currency of the asset to be received.
   */
  std::string_view getRecvCurrency() const override;

  /**
   * Get the currency of the asset to be used.
   * @return The currency of the asset to be used.
   */
  std::string_view getUsedCurrency() const override;

private:
  const Symbol symbol_;
  const Position position_;
  const boost::multiprecision::cpp_dec_float_50 &offerQty_;
  boost::multiprecision::cpp_dec_float_50 orderQty_;
  const boost::multiprecision::cpp_dec_float_50 &orderPrice_;
  const std::string recvCurrency_;
  const std::string usedCurrency_;
};