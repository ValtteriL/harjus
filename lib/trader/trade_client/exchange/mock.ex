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
      quantity_quote: Decimal.new("1"),
      quantity_fee: Decimal.new("0.1"),
      fee_currency: "BNB"
    }
  end
end
