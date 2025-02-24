defmodule Trader.TradeClient.Impl do
  @moduledoc """
  Implementation of the trade client
  """

  require Decimal

  alias Trader.TradeClient.Exchange
  alias Types.TradeReport
  alias Types.TradingSymbol

  def new do
    Exchange.new()
  end

  @spec limit_order(
          trading_symbol :: TradingSymbol.t(),
          quantity :: Decimal.t(),
          price :: Decimal.t()
        ) :: trade_report :: TradeReport.t()
  def limit_order(trading_symbol = %TradingSymbol{}, quantity, price)
      when Decimal.is_decimal(quantity) and Decimal.is_decimal(price) do
    Exchange.limit_order(trading_symbol, quantity, price)
  end

  @spec market_order(
          trading_symbol :: TradingSymbol.t(),
          quantity :: Decimal.t()
        ) :: trade_report :: TradeReport.t()
  def market_order(trading_symbol = %TradingSymbol{}, quantity)
      when Decimal.is_decimal(quantity) do
    Exchange.market_order(trading_symbol, quantity)
  end
end
