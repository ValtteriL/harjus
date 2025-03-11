defmodule TradeClient.Exchange do
  @moduledoc """
  Exchange behaviour
  """
  alias Types.TradeReport
  alias Types.TradingSymbol

  require Decimal

  @callback new() :: any()
  @callback limit_order(TradingSymbol.t(), Decimal.t(), Decimal.t()) ::
              {:executed, TradeReport.t()} | {:expired, any()}

  def new, do: impl().new()

  def limit_order(trading_symbol = %TradingSymbol{}, quantity, price)
      when Decimal.is_decimal(quantity) and Decimal.is_decimal(price),
      do: impl().limit_order(trading_symbol, quantity, price)

  defp impl, do: Application.get_env(:harjus, :trade_client_exchange)
end
