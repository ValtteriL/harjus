defmodule Trader.TradeClient.Exchange.Binance do
  @moduledoc """
  Implementation of the trade client for Binance

  Manages FIX session state, makes Trade requests, returns Trade reports

  https://github.com/binance/binance-spot-api-docs/blob/master/fix-api.md
  """

  @behaviour Trader.TradeClient.Exchange

  alias Trader.TradeClient.Exchange.Binance.Impl
  alias Trader.TradeClient.Exchange.Binance.Server
  alias Types.TradeReport
  alias Types.TradingSymbol

  require Decimal

  @spec new() :: any()
  def new do
    GenServer.start_link(Server, Impl.new(), name: __MODULE__)
  end

  @spec market_order(
          trading_symbol :: TradingSymbol.t(),
          quantity :: Decimal.t()
        ) :: TradeReport.t()
  def market_order(trading_symbol = %TradingSymbol{}, quantity)
      when Decimal.is_decimal(quantity) do
    GenServer.call(__MODULE__, {:market_order, {trading_symbol, quantity}})
  end
end
