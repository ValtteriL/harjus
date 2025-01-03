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
    assert 1 ==
             BinanceFixApi.logon(
               1,
               "sBRXrJx2DsOraMXOaUovEhgVRcjOvCtQwnWj8VxkOh1xqboS02SPGfKi2h8spZJb",
               "MC4CAQAwBQYDK2VwBCIEIIJEYWtGBrhACmb9Dvy+qa8WEf0lQOl1s4CLIAB9m89u"
             )
  end

  test "generates correct market order request" do
    assert 1 == BinanceFixApi.market_order_request(1, {"BTCUSDT", :long}, 1)
  end

  test "parses heartbeat message" do
    id = "another_id"

    msg =
      "8=FIX.4.4|9=12|35=0|34=1|49=binance|56=client|112=#{id}|52=20210101-00:00:00.000|10=000|"

    assert {:heartbeat} ==
             BinanceFixApi.parse_message(str_message_to_binary(msg))
  end

  test "parses test_request message" do
    assert 1 == 0
  end

  test "parses reject message" do
    assert 1 == 0
  end

  test "parses logon message" do
    assert 1 == 0
  end

  test "parses news message" do
    assert 1 == 0
  end

  test "parses execution_report message" do
    assert 1 == 0
  end

  test "parses unknown message" do
    assert 1 == 0
  end

  @doc """
  Converts a string |-delimited FIX message to a binary message delimited with soh (1)
  """
  defp str_message_to_binary(str_message) do
    str_message
    |> :binary.split("|", [:global])
    |> Enum.join(<<1>>)
  end
end
