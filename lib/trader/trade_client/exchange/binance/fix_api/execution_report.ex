defmodule Trader.TradeClient.Exchange.Binance.FixApi.ExecutionReport do
  @moduledoc "execution report type"

  @type t :: %__MODULE__{}

  @enforce_keys [
    :order_status,
    :quantity_base,
    :quantity_quote,
    :symbol,
    :side,
    :fee_currency,
    :fee_amount,
    :client_order_id
  ]
  defstruct [
    :order_status,
    :quantity_base,
    :quantity_quote,
    :symbol,
    :side,
    :fee_currency,
    :fee_amount,
    :client_order_id
  ]

  defmodule ExecutionType do
    @moduledoc "execution type values"
    def new, do: "0"
    def canceled, do: "4"
    def replaced, do: "5"
    def rejected, do: "8"
    def trade, do: "F"
    def expired, do: "C"
  end

  defmodule OrderStatus do
    @moduledoc "order status values"
    def new, do: "0"
    def partially_filled, do: "1"
    def filled, do: "2"
    def canceled, do: "4"
    def pending_cancel, do: "6"
    def rejected, do: "8"
    def pending_new, do: "A"
    def expired, do: "C"
  end
end
