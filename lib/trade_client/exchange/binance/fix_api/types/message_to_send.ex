defmodule TradeClient.Exchange.Binance.FixApi.Types.MessageToSend do
  @moduledoc "serializer argument map"
  @type t :: %__MODULE__{}
  defstruct seqnum: 0,
            msg_type: nil,
            sender: nil,
            orig_sending_time: nil,
            extra_header: [],
            body: []
end
