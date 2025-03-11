defmodule TradeClient.Exchange.Binance.State do
  @moduledoc """
  State of the trade client
  """

  @enforce_keys [:socket, :seq_num, :sender_comp_id, :outstanding_execution_reports]

  @type t :: %{
          socket: any(),
          seq_num: integer(),
          sender_comp_id: String.t(),
          outstanding_execution_reports: %{
            (client_order_id :: String.t()) => from :: any()
          }
        }

  defstruct [:socket, :seq_num, :sender_comp_id, :outstanding_execution_reports]
end
