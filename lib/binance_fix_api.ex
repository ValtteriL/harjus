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

  # InMessage types
  @msg_type_heartbeat "0"
  @msg_type_logon "A"
  @tag_msg_type "35"
  @tag_seqnum "34"
  @tag_sender_comp_id "49"
  @tag_sending_time "52"
  @tag_target_comp_id "56"
  @tag_poss_dup_flag "43"
  @tag_orig_sending_time "122"

  # InMessage types logon
  @tag_encrypt_method "98"
  @tag_heartbeat_interval "108"
  @tag_raw_data_length "95"
  @tag_raw_data "96"
  @tag_reset_seq_num_flag "141"
  @tag_username "553"
  @tag_message_handling "25035"
  @tag_response_mode "25036"
  @tag_drop_copy_flag "9406"

  @message_handling_unordered 1
  @response_mode_everything 1
  @drop_copy_off "N"

  # dummy defaults
  @sender "123"

  def logon(seq_num, public_key, private_key) do
    ts = timestamp()

    signature = sign({@msg_type_logon, @sender, "SPOT", seq_num, ts}, private_key)
    signature_length = String.length(signature)

    serialize(
      %MessageToSend{
        seqnum: seq_num,
        msg_type: @msg_type_logon,
        sender: @sender,
        orig_sending_time: nil,
        body: [
          {@tag_encrypt_method, 0},
          {@tag_heartbeat_interval, 60},
          {@tag_raw_data_length, signature_length},
          {@tag_raw_data, signature},
          {@tag_reset_seq_num_flag, "Y"},
          {@tag_username, public_key},
          {@tag_message_handling, @message_handling_unordered},
          {@tag_response_mode, @response_mode_everything},
          {@tag_drop_copy_flag, @drop_copy_off}
        ]
      },
      ts
    )
  end

  def market_order_request(seq_num, trading_symbol, quantity) do
    # TODO
  end

  def heartbeat(seq_num) do
    serialize(
      %MessageToSend{
        seqnum: seq_num,
        msg_type: @msg_type_heartbeat,
        sender: @sender,
        orig_sending_time: nil,
        body: []
      },
      timestamp()
    )
  end

  def parse_message(message) do
    # TODO
  end

  # private functions

  defp sign({msg_type, sender_comp_id, target_comp_id, msg_seq_num, sending_time}, private_key) do
    # The signature payload is a text string constructed by concatenating the VALUES of the following fields in this exact order, separated by the SOH character
    # MsgType (35)
    # SenderCompID (49)
    # TargetCompID (56)
    # MsgSeqNum (34)
    # SendingTime (52)

    # Sign the payload using your private key. Encode the signature with base64.

    payload = <<msg_type, 1, sender_comp_id, 1, target_comp_id, 1, msg_seq_num, 1, sending_time>>

    # convert key into usable format
    [{'PrivateKeyInfo', _, :not_encrypted} = pem_entry] = :public_key.pem_decode(private_key)
    decoded_key = :public_key.pem_entry_decode(pem_entry)

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
            {@tag_sender_comp_id, sender},
            {@tag_sending_time, sending_time},
            {@tag_target_comp_id, "SPOT"}
          ]

        true ->
          [
            {@tag_sender_comp_id, sender},
            {@tag_poss_dup_flag, true},
            {@tag_sending_time, sending_time},
            {@tag_orig_sending_time, orig_sending_time},
            {@tag_target_comp_id, "SPOT"}
          ]
      end

    fields = header ++ extra_header ++ body

    {:ok, body, bin_len, cs_total} =
      fields_to_bin([{@tag_msg_type, msg_type}, {@tag_seqnum, seqnum} | fields])

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

  def bin_sum(<<>>, acc), do: acc

  def bin_sum(<<value::binary-size(1), rest::binary>>, acc) do
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
