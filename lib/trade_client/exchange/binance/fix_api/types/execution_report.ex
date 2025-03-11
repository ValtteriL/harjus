defmodule TradeClient.Exchange.Binance.FixApi.Types.ExecutionReport do
  @moduledoc "execution report type"

  alias TradeClient.Exchange.Binance.FixApi.Types.ExecutionReport.Fee

  @type t :: %__MODULE__{
          order_status: String.t(),
          quantity_base: Decimal.t(),
          quantity_quote: Decimal.t(),
          symbol: String.t(),
          side: String.t(),
          fees: [Fee.t()],
          client_order_id: String.t()
        }

  @enforce_keys [
    :order_status,
    :quantity_base,
    :quantity_quote,
    :symbol,
    :side,
    :fees,
    :client_order_id
  ]
  defstruct [
    :order_status,
    :quantity_base,
    :quantity_quote,
    :symbol,
    :side,
    :fees,
    :client_order_id,
    :error_msg
  ]

  defmodule Fee do
    @moduledoc "fee group"
    @type t :: %__MODULE__{
            fee_currency: String.t(),
            fee_amount: Decimal.t()
          }

    @enforce_keys [
      :fee_currency,
      :fee_amount
    ]
    defstruct [
      :fee_currency,
      :fee_amount
    ]
  end

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
