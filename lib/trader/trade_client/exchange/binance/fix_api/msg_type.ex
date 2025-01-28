defmodule Trader.TradeClient.Exchange.Binance.FixApi.MsgType do
  @moduledoc "message type enum"
  def heartbeat, do: "0"
  def test_request, do: "1"
  def logon, do: "A"
  def news, do: "B"
  def execution_report, do: "8"
  def reject, do: "3"
  def single_order_entry, do: "D"
end
