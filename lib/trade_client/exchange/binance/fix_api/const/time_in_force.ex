defmodule TradeClient.Exchange.Binance.FixApi.Const.TimeInForce do
  @moduledoc "TimeInForce values"
  def good_till_cancel, do: "1"
  def immediate_or_cancel, do: "3"
  def fill_or_kill, do: "4"
end
