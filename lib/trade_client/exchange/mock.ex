defmodule TradeClient.Exchange.Mock do
  @moduledoc "Mock for trade client"

  @behaviour TradeClient.Exchange

  alias Types.TradeReport
  alias Types.TradingSymbol
  require Decimal

  def new, do: {:ok, self()}

  def limit_order(trading_symbol = %TradingSymbol{}, quantity, _price)
      when Decimal.is_decimal(quantity) do
    {:executed, report(trading_symbol, quantity)}
  end

  defp report(trading_symbol, quantity) do
    %TradeReport{
      symbol: trading_symbol.symbol,
      position: [:long, :short] |> Enum.random(),
      quantity_base: Decimal.from_float(1.0),
      quantity_quote: quantity,
      fees: [
        %TradeReport.Fee{
          fee_currency: "BNB",
          fee_amount: Decimal.from_float(0.1)
        }
      ]
    }
  end
end
