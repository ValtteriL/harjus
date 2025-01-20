defmodule Trader.TradeClient.Impl do
  @moduledoc """
  Implementation of the trade client
  """

  @exchange Application.compile_env(:harjus, :trade_client_exchange)

  alias Types.TradeReport
  alias Types.TradingSymbol

  def new do
    @exchange.new()
  end

  @spec market_order(
          trading_symbol :: TradingSymbol.t(),
          quantity :: Decimal.t()
        ) :: trade_report :: TradeReport.t()
  def market_order(trading_symbol, quantity) do
    @exchange.market_order(trading_symbol, quantity)
  end
end
