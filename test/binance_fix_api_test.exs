defmodule BinanceFixApiTest do
  @moduledoc "Tests for BinanceFixApi"
  use ExUnit.Case
  doctest BinanceFixApi

  test "generates correct heartbeat message" do
    id = "some_id"
    msg_type_part = "#{BinanceFixApi.Tag.msg_type()}=#{BinanceFixApi.MsgType.heartbeat()}"

    # correct msg type
    <<"8=FIX.4.4", 1, "9=65", 1, ^msg_type_part::binary, rest::binary>> =
      BinanceFixApi.heartbeat(1, id)

    # rest contains id
    assert String.contains?(rest, "#{BinanceFixApi.Tag.test_request_id()}=#{id}")
  end

  test "generates correct logon request" do
    # practically incorrect, but msg type is correct
    msg =
      "8=FIX.4.4|9=12|35=A|34=1|49=binance|56=client|112=another_id|52=20210101-00:00:00.000|98=0|108=30|10=000|"

    pubkey = "sBRXrJx2DsOraMXOaUovEhgVRcjOvCtQwnWj8VxkOh1xqboS02SPGfKi2h8spZJb"

    logon_msg =
      BinanceFixApi.logon(
        1,
        pubkey,
        "MC4CAQAwBQYDK2VwBCIEIIJEYWtGBrhACmb9Dvy+qa8WEf0lQOl1s4CLIAB9m89u"
      )

    # correct msg type
    assert String.contains?(
             logon_msg,
             "#{BinanceFixApi.Tag.msg_type()}=#{BinanceFixApi.MsgType.logon()}"
           )

    # correct user
    assert String.contains?(logon_msg, "#{BinanceFixApi.Tag.username()}=#{pubkey}")
  end

  test "generates correct market order request" do
    quantity = 1
    symbol = "BTCUSDT"

    msg = BinanceFixApi.market_order_request(1, {symbol, :long}, quantity)

    # correct msg type
    assert String.contains?(
             msg,
             "#{BinanceFixApi.Tag.msg_type()}=#{BinanceFixApi.MsgType.single_order_entry()}"
           )

    # correct symbol
    assert String.contains?(msg, "#{BinanceFixApi.Tag.symbol()}=#{symbol}")

    # correct side
    assert String.contains?(msg, "#{BinanceFixApi.Tag.side()}=#{BinanceFixApi.OrderSide.buy()}")

    # correct quantity
    assert String.contains?(msg, "#{BinanceFixApi.Tag.cash_order_qty()}=#{quantity}")

    # correct order type
    assert String.contains?(
             msg,
             "#{BinanceFixApi.Tag.order_type()}=#{BinanceFixApi.OrderType.market()}"
           )
  end

  test "parses heartbeat message" do
    id = "another_id"

    msg =
      "8=FIX.4.4|9=12|35=0|34=1|49=binance|56=client|112=#{id}|52=20210101-00:00:00.000|10=000|"

    assert {:heartbeat} ==
             BinanceFixApi.parse_message(str_message_to_binary(msg))
  end

  test "parses test_request message" do
    id = "some_id"

    msg =
      "8=FIX.4.4|9=12|35=1|34=1|49=binance|56=client|112=#{id}|52=20210101-00:00:00.000|10=000|"

    assert {:test_request, id} ==
             BinanceFixApi.parse_message(str_message_to_binary(msg))
  end

  test "parses reject message" do
    msg =
      "8=FIX.4.4|9=12|35=3|34=1|49=binance|56=client|112=another_id|52=20210101-00:00:00.000|10=000|"

    assert {:reject} == BinanceFixApi.parse_message(str_message_to_binary(msg))
  end

  test "parses logon message" do
    # practically incorrect, but msg type is correct
    msg =
      "8=FIX.4.4|9=12|35=A|34=1|49=binance|56=client|112=another_id|52=20210101-00:00:00.000|98=0|108=30|10=000|"

    assert {:logon} == BinanceFixApi.parse_message(str_message_to_binary(msg))
  end

  test "parses news message" do
    msg =
      "8=FIX.4.4|9=12|35=B|34=1|49=binance|56=client|112=another_id|52=20210101-00:00:00.000|10=000|"

    assert {:news} == BinanceFixApi.parse_message(str_message_to_binary(msg))
  end

  test "parses execution_report message" do
    status = "1"
    quantity_base = 2.0
    quantity_quote = 3.0
    symbol = "BTCUSDT"
    side = "4"
    fee_currency = "USDT"
    fee_amount = 5.0

    report_fields =
      [
        pair(BinanceFixApi.Tag.order_status(), status),
        pair(BinanceFixApi.Tag.quantity_base(), quantity_base),
        pair(BinanceFixApi.Tag.quantity_quote(), quantity_quote),
        pair(BinanceFixApi.Tag.symbol(), symbol),
        pair(BinanceFixApi.Tag.side(), side),
        pair(BinanceFixApi.Tag.fee_currency(), fee_currency),
        pair(BinanceFixApi.Tag.fee_amount(), fee_amount)
      ]
      |> Enum.join("|")

    msg =
      "8=FIX.4.4|9=12|35=8|34=1|49=binance|56=client|#{report_fields}|52=20210101-00:00:00.000|10=000|"

    assert {:execution_report,
            %BinanceFixApi.ExecutionReport{
              order_status: status,
              quantity_base: quantity_base,
              quantity_quote: quantity_quote,
              symbol: symbol,
              side: side,
              fee_currency: fee_currency,
              fee_amount: fee_amount
            }} ==
             BinanceFixApi.parse_message(str_message_to_binary(msg))
  end

  test "parses unknown message" do
    msg = "whateva"
    assert {:unknown, msg} == BinanceFixApi.parse_message(msg)
  end

  # Converts a string |-delimited FIX message to a binary message delimited with soh (1)
  defp str_message_to_binary(str_message) do
    str_message
    |> :binary.split("|", [:global])
    |> Enum.join(<<1>>)
  end

  # create pair
  def pair(tag, value) do
    "#{tag}=#{value}"
  end
end
