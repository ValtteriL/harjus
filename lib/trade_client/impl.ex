defmodule TradeClient.Impl do
  @moduledoc """
  Implementation of the trade client
  """

  require Decimal

  alias TradeClient.Exchange
  alias Types.TradeReport
  alias Types.TradingSymbol

  @spec new() :: {:ok, pid}
  def new do
    Decimal.Context.set(%Decimal.Context{Decimal.Context.get() | precision: 16})
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
