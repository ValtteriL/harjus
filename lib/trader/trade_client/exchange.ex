defmodule Trader.TradeClient.Exchange do
  @moduledoc """
  Exchange behaviour
  """
  alias Types.TradeReport
  alias Types.TradingSymbol

  require Decimal

  @callback new() :: any()
  @callback market_order(TradingSymbol.t(), Decimal.t()) :: TradeReport.t()
  @callback limit_order(TradingSymbol.t(), Decimal.t(), Decimal.t()) :: TradeReport.t()

  def new, do: impl().new()

  def market_order(trading_symbol = %TradingSymbol{}, quantity) when Decimal.is_decimal(quantity),
    do: impl().market_order(trading_symbol, quantity)

  def limit_order(trading_symbol = %TradingSymbol{}, quantity, price)
      when Decimal.is_decimal(quantity) and Decimal.is_decimal(price),
      do: impl().limit_order(trading_symbol, quantity, price)

  defp impl, do: Application.get_env(:harjus, :trade_client_exchange)
end
