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
        ) :: {:executed, TradeReport.t()} | {:expired, any()}
  def limit_order(trading_symbol = %TradingSymbol{}, quantity, price)
      when Decimal.is_decimal(quantity) and Decimal.is_decimal(price) do
    Exchange.limit_order(trading_symbol, quantity, price)
  end
end
