defmodule BinanceFixApiTest do
  @moduledoc "Tests for BinanceFixApi"
  use ExUnit.Case
  doctest BinanceFixApi

  test "generates correct heartbeat message" do
    assert 1 == BinanceFixApi.heartbeat(1, "some_id")
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
    assert 1 ==
             BinanceFixApi.parse_message(
               "8=FIX.4.4|9=000|35=0|34=1|49=binance|56=client|52=20210101-00:00:00.000|10=000|"
             )
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
end
