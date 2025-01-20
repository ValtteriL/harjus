defmodule Trader.TradeClient.Exchange do
  @moduledoc """
  Exchange behaviour
  """
  alias Types.TradeReport
  alias Types.TradingSymbol

  @callback new() :: any()
  @callback market_order(TradingSymbol.t(), Decimal.t()) :: TradeReport.t()
end
