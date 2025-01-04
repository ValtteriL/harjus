defmodule BinanceFixApi do
  @moduledoc """
  Functions for constructing & parsing Binance FIX API messages

  https://github.com/binance/binance-spot-api-docs/blob/master/fix-api.md
  """

  @type trading_symbol() :: {charlist(), :long | :short}

  defmodule MessageToSend do
    @moduledoc "serializer argument map"
    @type t :: %MessageToSend{}
    defstruct seqnum: 0,
              msg_type: nil,
              sender: nil,
              orig_sending_time: nil,
              extra_header: [],
              body: []
  end

  defmodule ExecutionReport do
    @moduledoc "execution report type"

    @type t :: %ExecutionReport{}

    @enforce_keys [
      :order_status,
      :quantity_base,
      :quantity_quote,
      :symbol,
      :side,
      :fee_currency,
      :fee_amount
    ]
    defstruct [
      :order_status,
      :quantity_base,
      :quantity_quote,
      :symbol,
      :side,
      :fee_currency,
      :fee_amount
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

  defmodule MsgType do
    @moduledoc "message type enum"
    def heartbeat, do: "0"
    def test_request, do: "1"
    def logon, do: "A"
    def news, do: "B"
    def execution_report, do: "8"
    def reject, do: "3"
    def single_order_entry, do: "D"
  end

  @msg_type_heartbeat "0"
  @msg_type_test_request "1"
  @msg_type_logon "A"
  @msg_type_news "B"
  @msg_type_execution_report "8"
  @msg_type_reject "3"

  defmodule Tag do
    @moduledoc "tag enum"
    def msg_type, do: "35"
    def seqnum, do: "34"
    def sender_comp_id, do: "49"
    def sending_time, do: "52"
    def target_comp_id, do: "56"
    def poss_dup_flag, do: "43"
    def orig_sending_time, do: "122"
    def encrypt_method, do: "98"
    def heartbeat_interval, do: "108"
    def raw_data_length, do: "95"
    def raw_data, do: "96"
    def reset_seq_num_flag, do: "141"
    def username, do: "553"
    def message_handling, do: "25035"
    def response_mode, do: "25036"
    def drop_copy_flag, do: "9406"
    def cl_order_id, do: "11"
    def order_type, do: "40"
    def side, do: "54"
    def symbol, do: "55"
    def cash_order_qty, do: "152"
    def order_status, do: "39"
    def quantity_base, do: "14"
    def quantity_quote, do: "25017"
    def fee_currency, do: "138"
    def fee_amount, do: "137"
    def test_request_id, do: "112"
    def reject_text, do: "58"
  end

  defmodule MessageHandling do
    @moduledoc "Message handling values"
    def unordered, do: "1"
  end

  defmodule ResponseMode do
    @moduledoc "Response mode values"
    def everything, do: "1"
  end

  @soh 1

  defmodule OrderType do
    @moduledoc "Order type enum"
    def market, do: "1"
  end

  defmodule OrderSide do
    @moduledoc "Order side values"
    def buy, do: "1"
    def sell, do: "2"
  end

  # dummy defaults
  defp sender, do: "123"

  @doc """
  Construct a logon message

  ## Parameters
    * `seq_num` - sequence number
    * `api_key` - api key received when uploading public key to Binance
    * `private_key` - private key (in PEM format without "---BEGIN PUBLIC...")
  """
  def logon(seq_num, api_key, private_key) do
    ts = timestamp()

    signature = sign({MsgType.logon(), sender(), "SPOT", seq_num, ts}, private_key)
    signature_length = String.length(signature)

    serialize(
      %MessageToSend{
        seqnum: seq_num,
        msg_type: MsgType.logon(),
        sender: sender(),
        orig_sending_time: nil,
        body: [
          {Tag.encrypt_method(), 0},
          {Tag.heartbeat_interval(), 60},
          {Tag.raw_data_length(), signature_length},
          {Tag.raw_data(), signature},
          {Tag.reset_seq_num_flag(), true},
          {Tag.username(), api_key},
          {Tag.message_handling(), MessageHandling.unordered()},
          {Tag.response_mode(), ResponseMode.everything()},
          {Tag.drop_copy_flag(), false}
        ]
      },
      ts
    )
  end

  @doc """
  Construct a market order request message

  ## Parameters
    * `seq_num` - sequence number
    * `trading_symbol` - trading symbol
    * `quantity` - quantity (in quote asset units)
  """
  def market_order_request(seq_num, trading_symbol, quantity) do
    side =
      case trading_symbol do
        {_, :long} -> OrderSide.buy()
        {_, :short} -> OrderSide.sell()
      end

    {symbol, _} = trading_symbol

    serialize(
      %MessageToSend{
        seqnum: seq_num,
        msg_type: MsgType.single_order_entry(),
        sender: sender(),
        orig_sending_time: nil,
        body: [
          {Tag.cl_order_id(), "123"},
          {Tag.order_type(), OrderType.market()},
          {Tag.side(), side},
          {Tag.symbol(), symbol},
          {Tag.cash_order_qty(), quantity}
        ]
      },
      timestamp()
    )
  end

  @doc """
  Construct a heartbeat message

  ## Parameters
    * `seq_num` - sequence number
    * `test_request_id` - test request id
  """
  def heartbeat(seq_num, test_request_id) do
    serialize(
      %MessageToSend{
        seqnum: seq_num,
        msg_type: MsgType.heartbeat(),
        sender: sender(),
        orig_sending_time: nil,
        body: [
          {Tag.test_request_id(), test_request_id}
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
    fields[Tag.reject_text()]
  end

  # return rest req id
  defp parse_test_request(message) do
    fields = parse_message_into_fields(message)
    fields[Tag.test_request_id()]
  end

  defp parse_execution_report(message) do
    fields = parse_message_into_fields(message)

    %ExecutionReport{
      order_status: fields[Tag.order_status()],
      quantity_base: String.to_float(fields[Tag.quantity_base()]),
      quantity_quote: String.to_float(fields[Tag.quantity_quote()]),
      symbol: fields[Tag.symbol()],
      side: fields[Tag.side()],
      fee_currency: fields[Tag.fee_currency()],
      fee_amount: String.to_float(fields[Tag.fee_amount()])
    }
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

    # convert key into usable format
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

  @spec serialize(MessageToSend.t(), DateTime.t(), boolean()) :: binary()
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
      case resend do
        false ->
          [
            {Tag.sender_comp_id(), sender},
            {Tag.sending_time(), sending_time},
            {Tag.target_comp_id(), "SPOT"}
          ]

        true ->
          [
            {Tag.sender_comp_id(), sender},
            {Tag.poss_dup_flag(), true},
            {Tag.sending_time(), sending_time},
            {Tag.orig_sending_time(), orig_sending_time},
            {Tag.target_comp_id(), "SPOT"}
          ]
      end

    fields = header ++ extra_header ++ body

    {:ok, body, bin_len, cs_total} =
      fields_to_bin([{Tag.msg_type(), msg_type}, {Tag.seqnum(), seqnum} | fields])

    head = <<"8=FIX.4.4", 1, "9=", bin_len::binary, 1>>
    checksum_bin = calculate_checksum(cs_total, head)
    <<head::binary, body::binary, "10=", checksum_bin::binary, 1>>
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
    pair = <<tag::binary, "=", bin_value::binary, 1>>
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
