defmodule TradeClient do
  @moduledoc """
  Client for placing trades
  """

  alias TradeClient.Impl
  alias TradeClient.Server
  alias Types.TradeReport
  alias Types.TradingSymbol

  def start_link do
    GenServer.start_link(Server, Impl.new(), name: __MODULE__)
  end

  @spec market_order(
          trading_symbol :: TradingSymbol.t(),
          quantity :: Decimal.t()
        ) :: trade_report :: TradeReport.t()
  def market_order(trading_symbol, quantity) do
    GenServer.call(__MODULE__, {:market_order, {trading_symbol, quantity}})
  end
end
