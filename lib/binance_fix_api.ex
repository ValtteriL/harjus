defmodule BinanceFixApi do
  @moduledoc """
  Functions for constructing & parsing Binance FIX API messages

  https://github.com/binance/binance-spot-api-docs/blob/master/fix-api.md
  """

  @type trading_symbol() :: {charlist(), :long | :short}

  # InMessage types
  @msg_type_heartbeat "0"
  @soh_character 1

  def logon(public_key, private_key) do
  end

  def market_order_request(trading_symbol, quantity) do
    # TODO
  end

  def heartbeat do
    timestamp = timestamp()
    seq_num = 1

    header =
      <<"8=FIX.4.4", @soh_character, "9=", bin_len::binary, @soh_character, "35=",
        @msg_type_heartbeat, @soh_character, "49=123", @soh_character, "56=SPOT", @soh_character,
        "34=", seq_num::binary, @soh_character, "52=", timestamp::binary, @soh_character>>

    checksum = calculate_checksum(header)
    trailer = <<"10=", checksum::binary, @soh_character>>

    <<header::binary, body::binary, trailer::binary>>
  end

  def parse_message(message) do
    # TODO
  end

  # private functions
  defp timestamp do
    Calendar.strftime(DateTime.utc_now(), "%Y%m%d-%H:%M:%S.%f")
  end

  defp calculate_checksum(header) do
    # TODO
  end
end
