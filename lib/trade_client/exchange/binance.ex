defmodule TradeClient.Exchange.Binance do
  @moduledoc """
  Implementation of the trade client for Binance

  Manages FIX session state, makes Trade requests, returns Trade reports

  https://github.com/binance/binance-spot-api-docs/blob/master/fix-api.md
  """

  @behaviour TradeClient.Exchange

  alias TradeClient.Exchange.Binance.Server
  alias Types.TradeReport
  alias Types.TradingSymbol

  require Decimal

  @spec new() :: {:ok, pid()}
  def new do
    GenServer.start_link(Server, [], name: __MODULE__)
  end

  @spec limit_order(
          trading_symbol :: TradingSymbol.t(),
          quantity :: Decimal.t(),
          price :: Decimal.t()
        ) :: {:executed, TradeReport.t()} | {:expired, any()}
  def limit_order(trading_symbol = %TradingSymbol{}, quantity, price)
      when Decimal.is_decimal(quantity) and Decimal.is_decimal(price) do
    GenServer.call(__MODULE__, {:limit_order, {trading_symbol, quantity, price}}, 5_000)
  end
end
