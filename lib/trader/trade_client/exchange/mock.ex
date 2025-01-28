defmodule Trader.TradeClient.Exchange.Mock do
  @moduledoc "Mock for trade client"

  @behaviour Trader.TradeClient.Exchange

  alias Types.TradeReport

  def new, do: :ok

  def market_order(trading_symbol, quantity) do
    %TradeReport{
      symbol: trading_symbol,
      position: [:long, :short] |> Enum.random(),
      quantity_base: quantity,
      quantity_quote: Decimal.from_float(1.0),
      quantity_fee: Decimal.from_float(0.1),
      fee_currency: "BNB"
    }
  end
end
