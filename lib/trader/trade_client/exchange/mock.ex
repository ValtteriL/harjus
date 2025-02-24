defmodule Trader.TradeClient.Exchange.Mock do
  @moduledoc "Mock for trade client"

  @behaviour Trader.TradeClient.Exchange

  alias Types.TradeReport
  alias Types.TradingSymbol
  require Decimal

  def new, do: :ok

  def market_order(trading_symbol = %TradingSymbol{}, quantity)
      when Decimal.is_decimal(quantity) do
    %TradeReport{
      symbol: trading_symbol.symbol,
      position: [:long, :short] |> Enum.random(),
      quantity_base: quantity,
      quantity_quote: Decimal.from_float(1.0),
      fees: [
        %TradeReport.Fee{
          fee_currency: "BNB",
          fee_amount: Decimal.from_float(0.1)
        }
      ]
    }
  end
end
