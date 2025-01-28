defmodule Trader.TradeClient.Exchange do
  @moduledoc """
  Exchange behaviour
  """
  alias Types.TradeReport
  alias Types.TradingSymbol

  require Decimal

  @callback new() :: any()
  @callback market_order(TradingSymbol.t(), Decimal.t()) :: TradeReport.t()

  def new, do: impl().new()

  def market_order(trading_symbol = %TradingSymbol{}, quantity) when Decimal.is_decimal(quantity),
    do: impl().market_order(trading_symbol, quantity)

  defp impl, do: Application.get_env(:harjus, :trade_client_exchange)
end
