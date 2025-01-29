defmodule Trader.TradeClient.Exchange.Binance.FixApi do
  @moduledoc """
  Functions for constructing & parsing Binance FIX API messages

  https://github.com/binance/binance-spot-api-docs/blob/master/fix-api.md
  """

  alias Trader.TradeClient.Exchange.Binance.FixApi.Impl
  alias Trader.TradeClient.Exchange.Binance.FixApi.Types.ExecutionReport
  alias Types.TradingSymbol

  @doc """
  Construct a logon message

  ## Parameters
    * `seq_num` - sequence number
    * `sender_comp_id` - sender comp id
    * `api_key` - api key received when uploading public key to Binance
    * `private_key` - private key (in PEM format without "---BEGIN PUBLIC...")
  """
  @spec logon(integer(), String.t(), String.t(), String.t()) :: binary()
  defdelegate logon(seq_num, sender_comp_id, api_key, private_key), to: Impl

  @doc """
  Construct a market order request message

  ## Parameters
    * `seq_num` - sequence number
    * `sender_comp_id` - sender comp id
    * `trading_symbol` - trading symbol
    * `quantity` - quantity (in quote asset units)
  """
  @spec market_order_request(integer(), String.t(), TradingSymbol.t(), Decimal.t(), String.t()) ::
          binary()
  defdelegate market_order_request(
                seq_num,
                sender_comp_id,
                trading_symbol,
                quantity,
                client_order_id
              ),
              to: Impl

  @doc """
  Construct a heartbeat message

  ## Parameters
    * `seq_num` - sequence number
    * `sender_comp_id` - sender comp id
    * `test_request_id` - test request id
  """
  @spec heartbeat(integer(), String.t(), String.t()) :: binary()
  defdelegate heartbeat(seq_num, sender_comp_id, test_request_id), to: Impl

  @doc """
  Parse a FIX message
  """
  @spec parse_message(binary()) ::
          {:heartbeat}
          | {:test_request, String.t()}
          | {:reject, String.t()}
          | {:logon}
          | {:news}
          | {:execution_report, ExecutionReport.t()}
          | {:unknown, any()}
  defdelegate parse_message(message), to: Impl
end
