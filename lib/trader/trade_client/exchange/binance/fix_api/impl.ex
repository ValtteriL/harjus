defmodule Trader.TradeClient.Exchange.Binance.FixApi.Impl do
  @moduledoc """
  Functions for constructing & parsing Binance FIX API messages

  https://github.com/binance/binance-spot-api-docs/blob/master/fix-api.md
  """

  alias Trader.TradeClient.Exchange.Binance.FixApi.Const
  alias Trader.TradeClient.Exchange.Binance.FixApi.Types.ExecutionReport
  alias Trader.TradeClient.Exchange.Binance.FixApi.Types.MessageToSend
  alias Types.TradingSymbol

  require Decimal

  @msg_type_heartbeat Const.MsgType.heartbeat()
  @msg_type_test_request Const.MsgType.test_request()
  @msg_type_logon Const.MsgType.logon()
  @msg_type_news Const.MsgType.news()
  @msg_type_execution_report Const.MsgType.execution_report()
  @msg_type_reject Const.MsgType.reject()

  @soh Const.Delimiter.soh()

  @doc """
  Construct a logon message

  ## Parameters
    * `seq_num` - sequence number
    * `sender_comp_id` - sender comp id
    * `api_key` - api key received when uploading public key to Binance
    * `private_key` - private key (in PEM format without "---BEGIN PUBLIC...")
  """
  @spec logon(integer(), String.t(), String.t(), String.t()) :: binary()
  def logon(seq_num, sender_comp_id = "" <> _, api_key = "" <> _, private_key = "" <> _)
      when is_integer(seq_num) and seq_num > 0 do
    ts = timestamp()

    signature = sign({Const.MsgType.logon(), sender_comp_id, "SPOT", seq_num, ts}, private_key)
    signature_length = String.length(signature)

    serialize(
      %MessageToSend{
        seqnum: seq_num,
        msg_type: Const.MsgType.logon(),
        sender: sender_comp_id,
        orig_sending_time: nil,
        body: [
          {Const.Tag.encrypt_method(), 0},
          {Const.Tag.heartbeat_interval(), 60},
          {Const.Tag.raw_data_length(), signature_length},
          {Const.Tag.raw_data(), signature},
          {Const.Tag.reset_seq_num_flag(), true},
          {Const.Tag.username(), api_key},
          {Const.Tag.message_handling(), Const.MessageHandling.unordered()},
          {Const.Tag.response_mode(), Const.ResponseMode.everything()},
          {Const.Tag.drop_copy_flag(), false}
        ]
      },
      ts
    )
  end

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
  def market_order_request(
        seq_num,
        sender_comp_id = "" <> _,
        trading_symbol = %TradingSymbol{},
        quantity,
        client_order_id = "" <> _
      )
      when Decimal.is_decimal(quantity) and is_integer(seq_num) and seq_num > 0 do
    side =
      case trading_symbol.position do
        :long -> Const.OrderSide.buy()
        :short -> Const.OrderSide.sell()
      end

    symbol = trading_symbol.symbol

    serialize(
      %MessageToSend{
        seqnum: seq_num,
        msg_type: Const.MsgType.single_order_entry(),
        sender: sender_comp_id,
        orig_sending_time: nil,
        body: [
          {Const.Tag.cl_order_id(), client_order_id},
          {Const.Tag.order_type(), Const.OrderType.market()},
          {Const.Tag.side(), side},
          {Const.Tag.symbol(), symbol},
          {Const.Tag.cash_order_qty(), Decimal.to_float(quantity)}
        ]
      },
      timestamp()
    )
  end

  @doc """
  Construct a heartbeat message

  ## Parameters
    * `seq_num` - sequence number
    * `sender_comp_id` - sender comp id
    * `test_request_id` - test request id
  """
  @spec heartbeat(integer(), String.t(), String.t()) :: binary()
  def heartbeat(seq_num, sender_comp_id = "" <> _, test_request_id = "" <> _)
      when is_integer(seq_num) and seq_num > 0 do
    serialize(
      %MessageToSend{
        seqnum: seq_num,
        msg_type: Const.MsgType.heartbeat(),
        sender: sender_comp_id,
        orig_sending_time: nil,
        body: [
          {Const.Tag.test_request_id(), test_request_id}
        ]
      },
      timestamp()
    )
  end

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
  def parse_message(<<"8=FIX.4.4", @soh, "9=", rest::binary>>) do
    # remove length
    [str_len, _] = :binary.split(rest, <<@soh>>)
    <<^str_len::binary, @soh, rest2::binary>> = rest

    # continue parsing
    parse_message(rest2)
  end

  def parse_message(<<"35=", @msg_type_heartbeat, _rest::binary>>), do: {:heartbeat}

  def parse_message(<<"35=", @msg_type_test_request, rest::binary>>),
    do: {:test_request, parse_test_request(rest)}

  def parse_message(<<"35=", @msg_type_reject, rest::binary>>),
    do: {:reject, parse_reject_message(rest)}

  def parse_message(<<"35=", @msg_type_logon, _rest::binary>>), do: {:logon}
  def parse_message(<<"35=", @msg_type_news, _rest::binary>>), do: {:news}

  def parse_message(<<"35=", @msg_type_execution_report, @soh, rest::binary>>),
    do: {:execution_report, parse_execution_report(rest)}

  def parse_message(msg), do: {:unknown, msg}

  # private functions

  defp parse_reject_message(message) do
    fields = parse_message_into_fields(message)
    fields[Const.Tag.reject_text()]
  end

  # return rest req id
  defp parse_test_request(message) do
    fields = parse_message_into_fields(message)
    fields[Const.Tag.test_request_id()]
  end

  defp parse_execution_report(message) do
    fields = parse_message_into_fields(message)
    fees = parse_fees(message)
    reject_text = Map.get(fields, Const.Tag.reject_text(), nil)

    IO.inspect(fields)

    %ExecutionReport{
      order_status: fields[Const.Tag.order_status()],
      quantity_base: Decimal.new(fields[Const.Tag.quantity_base()]),
      quantity_quote: Decimal.new(fields[Const.Tag.quantity_quote()]),
      symbol: fields[Const.Tag.symbol()],
      side: fields[Const.Tag.side()],
      fees: fees,
      client_order_id: fields[Const.Tag.cl_order_id()],
      error_msg: reject_text
    }
  end

  defp parse_fees(message) do
    :binary.split(message, <<@soh>>, [:global, :trim_all])
    |> Enum.map(fn p -> parse_field(p) end)
    |> Enum.filter(fn {tag, _} ->
      tag == Const.Tag.fee_currency() or tag == Const.Tag.fee_amount()
    end)
    |> Enum.chunk_every(2)
    |> Enum.map(fn [{_, currency}, {_, amount}] ->
      %ExecutionReport.Fee{
        fee_currency: currency,
        fee_amount: Decimal.from_float(String.to_float(amount))
      }
    end)
  end

  defp parse_message_into_fields(message) do
    :binary.split(message, <<@soh>>, [:global, :trim_all])
    |> Enum.map(fn p -> parse_field(p) end)
    |> Enum.into(%{})
  end

  defp parse_field(pair) do
    [name, value] = :binary.split(pair, <<"=">>)
    {name, :unicode.characters_to_binary(value, :latin1, :utf8)}
  end

  defp sign({msg_type, sender_comp_id, target_comp_id, msg_seq_num, sending_time}, private_key) do
    # The signature payload is a text string constructed by concatenating the VALUES
    # of the following fields in this exact order, separated by the SOH character
    # MsgType (35)
    # SenderCompID (49)
    # TargetCompID (56)
    # MsgSeqNum (34)
    # SendingTime (52)

    # Sign the payload using your private key. Encode the signature with base64.

    payload =
      [
        msg_type,
        sender_comp_id,
        target_comp_id,
        msg_seq_num,
        sending_time
      ]
      |> Enum.join(<<@soh>>)

    ed25519_sign(private_key, payload)
  end

  @spec ed25519_sign(private_key :: String.t(), payload :: String.t()) :: String.t()
  defp ed25519_sign(private_key, payload) do
    decoded_key =
      Enum.join(["-----BEGIN PRIVATE KEY-----\n", private_key, "\n-----END PRIVATE KEY-----\n"])
      |> :public_key.pem_decode()
      |> hd()
      |> :public_key.pem_entry_decode()

    signature = :public_key.sign(payload, :sha256, decoded_key)
    Base.encode64(signature)
  end

  defp timestamp do
    Calendar.strftime(DateTime.utc_now(), "%Y%m%d-%H:%M:%S.%f")
  end

  @spec serialize(MessageToSend.t(), String.t(), boolean()) :: binary()
  defp serialize(
         %MessageToSend{
           seqnum: seqnum,
           msg_type: msg_type,
           sender: sender,
           orig_sending_time: orig_sending_time,
           extra_header: extra_header,
           body: body
         },
         sending_time,
         resend \\ false
       ) do
    header =
      if resend,
        do: [
          {Const.Tag.sender_comp_id(), sender},
          {Const.Tag.poss_dup_flag(), true},
          {Const.Tag.sending_time(), sending_time},
          {Const.Tag.orig_sending_time(), orig_sending_time},
          {Const.Tag.target_comp_id(), "SPOT"}
        ],
        else: [
          {Const.Tag.sender_comp_id(), sender},
          {Const.Tag.sending_time(), sending_time},
          {Const.Tag.target_comp_id(), "SPOT"}
        ]

    fields = header ++ extra_header ++ body

    {:ok, body, bin_len, cs_total} =
      fields_to_bin([{Const.Tag.msg_type(), msg_type}, {Const.Tag.seqnum(), seqnum} | fields])

    head = <<"8=FIX.4.4", @soh, "9=", bin_len::binary, @soh>>
    checksum_bin = calculate_checksum(cs_total, head)
    <<head::binary, body::binary, "10=", checksum_bin::binary, @soh>>
  end

  defp fields_to_bin(fields), do: fields_to_bin(fields, [], 0, 0)

  defp fields_to_bin([], bin, len, cs_total) do
    result =
      bin
      |> Enum.reverse()
      |> IO.iodata_to_binary()

    {:ok, result, "#{len}", cs_total}
  end

  defp fields_to_bin([{tag, value} | rest], bin, len, cstot) do
    bin_value = serialize_value(value)
    pair = <<tag::binary, "=", bin_value::binary, @soh>>
    fields_to_bin(rest, [pair | bin], len + byte_size(pair), bin_sum(pair, cstot))
  end

  defp serialize_value(v) when is_binary(v) do
    :unicode.characters_to_binary(v, :utf8, :latin1)
  end

  defp serialize_value(v) when is_float(v) do
    :erlang.float_to_binary(v, [{:decimals, 10}, :compact])
  end

  defp serialize_value(v) when is_integer(v), do: Integer.to_string(v)
  defp serialize_value(true), do: "Y"
  defp serialize_value(false), do: "N"
  defp serialize_value(v) when is_atom(v), do: Atom.to_string(v)
  defp serialize_value(nil), do: ""

  defp bin_sum(<<>>, acc), do: acc

  defp bin_sum(<<value::binary-size(1), rest::binary>>, acc) do
    bin_sum(rest, acc + :binary.decode_unsigned(value))
  end

  defp calculate_checksum(cs_total, extra_bytes) do
    checksum = rem(bin_sum(extra_bytes, cs_total), 256)

    case checksum do
      cs when cs < 10 -> "00#{cs}"
      cs when cs < 100 -> "0#{cs}"
      cs -> "#{cs}"
    end
  end
end
