defmodule Trader.TradeClient.Exchange.Binance.FixApiTest do
  @moduledoc "Tests for FixApi"

  alias Trader.TradeClient.Exchange.Binance.FixApi
  alias Trader.TradeClient.Exchange.Binance.FixApi.Const.MsgType
  alias Trader.TradeClient.Exchange.Binance.FixApi.Const.OrderSide
  alias Trader.TradeClient.Exchange.Binance.FixApi.Const.OrderType
  alias Trader.TradeClient.Exchange.Binance.FixApi.Const.Tag
  alias Types.TradingSymbol

  use ExUnit.Case, async: true
  doctest FixApi
  require Decimal
  use PropCheck

  property "generates correct limit order request" do
    forall [seq, sender_comp_id, trading_symbol, order_qty, order_price, client_order_id] <- [
             pos_integer(),
             non_empty_string(),
             trading_symbol(),
             pos_decimal(),
             pos_decimal(),
             non_empty_string()
           ] do
      msg =
        FixApi.limit_order_request(
          seq,
          sender_comp_id,
          trading_symbol,
          order_qty,
          order_price,
          client_order_id
        )

      # correct header
      <<"8=FIX.4.4", 1, _rest::binary>> = msg

      # correct msg type
      assert String.contains?(
               msg,
               "#{Tag.msg_type()}=#{MsgType.single_order_entry()}"
             )

      # correct symbol
      assert String.contains?(msg, "#{Tag.symbol()}=#{trading_symbol.symbol}")

      # correct side
      correct_side =
        case trading_symbol.position do
          :long -> OrderSide.buy()
          _ -> OrderSide.sell()
        end

      assert String.contains?(msg, "#{Tag.side()}=#{correct_side}")

      # correct quantity (10 decimals)
      assert String.contains?(
               msg,
               "#{Tag.order_qty()}=#{:erlang.float_to_binary(Decimal.to_float(order_qty), [{:decimals, 10}, :compact])}"
             )

      # correct price (10 decimals)
      assert String.contains?(
               msg,
               "#{Tag.price()}=#{:erlang.float_to_binary(Decimal.to_float(order_price), [{:decimals, 10}, :compact])}"
             )

      # correct sender comp id
      assert String.contains?(msg, "#{Tag.sender_comp_id()}=#{sender_comp_id}")

      # correct order type
      assert String.contains?(
               msg,
               "#{Tag.order_type()}=#{OrderType.limit()}"
             )
    end
  end

  property "parses execution_report message" do
    forall [
             status,
             quantity_base,
             quantity_quote,
             symbol,
             side,
             client_order_id,
             fee_groups
           ] <- [
             pos_integer(),
             pos_decimal(),
             pos_decimal(),
             non_empty_string(),
             pos_integer(),
             non_empty_string(),
             list(fee_group())
           ] do
      fees_as_pairs =
        Enum.map(fee_groups, fn %{fee_currency: fee_currency, fee_amount: fee_amount} ->
          [
            pair(Tag.fee_currency(), fee_currency),
            pair(Tag.fee_amount(), Decimal.to_string(fee_amount))
          ]
        end)
        |> List.flatten()

      report_fields =
        ([
           pair(Tag.order_status(), Integer.to_string(status)),
           pair(Tag.quantity_base(), quantity_base),
           pair(Tag.quantity_quote(), quantity_quote),
           pair(Tag.symbol(), symbol),
           pair(Tag.side(), Integer.to_string(side)),
           pair(Tag.cl_order_id(), client_order_id),
           pair(Tag.no_misc_fees(), length(fee_groups))
         ] ++ fees_as_pairs)
        |> Enum.join("|")

      msg =
        "8=FIX.4.4|9=12|35=8|34=1|49=binance|56=client|#{report_fields}|52=20210101-00:00:00.000|10=000|"

      {:execution_report, parsed_msg} = FixApi.parse_message(str_message_to_binary(msg))

      # verify fields are correct

      order_status = Integer.to_string(status)
      side = Integer.to_string(side)

      %{
        order_status: ^order_status,
        quantity_base: ^quantity_base,
        quantity_quote: ^quantity_quote,
        symbol: ^symbol,
        side: ^side,
        fees: _,
        client_order_id: ^client_order_id
      } =
        parsed_msg

      # verify fees are correct
      assert Enum.count(fee_groups) == length(parsed_msg.fees)

      assert Enum.all?(parsed_msg.fees, fn %{fee_currency: fee_currency, fee_amount: fee_amount} ->
               Enum.any?(fee_groups, fn %{
                                          fee_currency: expected_fee_currency,
                                          fee_amount: expected_fee_amount
                                        } ->
                 fee_currency == expected_fee_currency and fee_amount == expected_fee_amount
               end)
             end)
    end
  end

  property "generates correct heartbeat message" do
    forall [sender_comp_id, id] <- [
             non_empty_string(),
             non_empty_string()
           ] do
      msg = FixApi.heartbeat(1, sender_comp_id, id)

      # correct header
      <<"8=FIX.4.4", 1, _rest::binary>> = msg

      # correct msg type
      assert String.contains?(
               msg,
               "#{Tag.msg_type()}=#{MsgType.heartbeat()}"
             )

      # correct sender comp id
      assert String.contains?(msg, "#{Tag.sender_comp_id()}=#{sender_comp_id}")

      # rest contains id
      assert String.contains?(msg, "#{Tag.test_request_id()}=#{id}")
    end
  end

  ## Generators ##

  defp fee_group do
    let [
      fee_currency <- non_empty_string(),
      fee_amount <- pos_decimal()
    ] do
      %{
        fee_currency: fee_currency,
        fee_amount: fee_amount
      }
    end
  end

  defp trading_symbol do
    let [
      symbol <- non_empty_string(),
      position <- union([:long, :short]),
      base_asset <- non_empty_string(),
      quote_asset <- non_empty_string(),
      precision <- pos_integer(),
      increment <- pos_decimal(),
      min_notional <- pos_decimal()
    ] do
      %TradingSymbol{
        symbol: symbol,
        position: position,
        base_asset: base_asset,
        quote_asset: quote_asset,
        base_asset_increment: increment,
        base_asset_precision: precision,
        quote_asset_increment: increment,
        quote_asset_precision: precision,
        min_notional: min_notional
      }
    end
  end

  defp pos_decimal do
    let float <- float(0.000001, :inf) do
      Decimal.from_float(float)
    end
  end

  defp non_empty_string do
    let charlist <- non_empty(elements(textdata())) do
      to_string(charlist)
    end
  end

  defp textdata do
    ~c"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789" ++
      ~c":;<=>?@ !#$%&'()*+-./[\\]^_`{|}~"
  end

  ## Unit tests ##

  test "generates correct logon request" do
    sender_comp_id = "asd123"

    pubkey = "sBRXrJx2DsOraMXOaUovEhgVRcjOvCtQwnWj8VxkOh1xqboS02SPGfKi2h8spZJb"
    privkey = "MC4CAQAwBQYDK2VwBCIEIIJEYWtGBrhACmb9Dvy+qa8WEf0lQOl1s4CLIAB9m89u"

    logon_msg =
      FixApi.logon(
        1,
        sender_comp_id,
        pubkey,
        privkey
      )

    # correct msg type
    assert String.contains?(
             logon_msg,
             "#{Tag.msg_type()}=#{MsgType.logon()}"
           )

    # correct user
    assert String.contains?(logon_msg, "#{Tag.username()}=#{pubkey}")

    # correct sender comp id
    assert String.contains?(logon_msg, "#{Tag.sender_comp_id()}=#{sender_comp_id}")
  end

  test "parses heartbeat message" do
    id = "another_id"

    msg =
      "8=FIX.4.4|9=12|35=0|34=1|49=binance|56=client|112=#{id}|52=20210101-00:00:00.000|10=000|"

    assert {:heartbeat} ==
             FixApi.parse_message(str_message_to_binary(msg))
  end

  test "parses test_request message" do
    id = "some_id"

    msg =
      "8=FIX.4.4|9=12|35=1|34=1|49=binance|56=client|112=#{id}|52=20210101-00:00:00.000|10=000|"

    assert {:test_request, id} ==
             FixApi.parse_message(str_message_to_binary(msg))
  end

  test "parses reject message" do
    reason = "some_reason"

    msg =
      "8=FIX.4.4|9=12|35=3|34=1|49=binance|56=client|112=another_id|52=20210101-00:00:00.000|58=#{reason}|10=000|"

    assert {:reject, reason} == FixApi.parse_message(str_message_to_binary(msg))
  end

  test "parses logon message" do
    # practically incorrect, but msg type is correct
    msg =
      "8=FIX.4.4|9=12|35=A|34=1|49=binance|56=client|112=another_id|52=20210101-00:00:00.000|98=0|108=30|10=000|"

    assert {:logon} == FixApi.parse_message(str_message_to_binary(msg))
  end

  test "parses news message" do
    msg =
      "8=FIX.4.4|9=12|35=B|34=1|49=binance|56=client|112=another_id|52=20210101-00:00:00.000|10=000|"

    assert {:news} == FixApi.parse_message(str_message_to_binary(msg))
  end

  test "parses unknown message" do
    msg = "whateva"
    assert {:unknown, msg} == FixApi.parse_message(msg)
  end

  test "parses own messages" do
    id = "some_id"
    sender_comp_id = "asd123"
    seq = 1
    client_order_id = "some_client_id"

    pubkey = "sBRXrJx2DsOraMXOaUovEhgVRcjOvCtQwnWj8VxkOh1xqboS02SPGfKi2h8spZJb"
    privkey = "MC4CAQAwBQYDK2VwBCIEIIJEYWtGBrhACmb9Dvy+qa8WEf0lQOl1s4CLIAB9m89u"

    assert {:heartbeat} ==
             FixApi.parse_message(FixApi.heartbeat(seq, sender_comp_id, id))

    assert {:logon} ==
             FixApi.parse_message(FixApi.logon(seq, sender_comp_id, pubkey, privkey))

    assert {:unknown, _} =
             FixApi.parse_message(
               FixApi.limit_order_request(
                 seq,
                 sender_comp_id,
                 %TradingSymbol{
                   symbol: "BTCETH",
                   position: :short,
                   base_asset: "ETH",
                   quote_asset: "BTC",
                   base_asset_increment: Decimal.new("0.0001"),
                   base_asset_precision: 8,
                   quote_asset_increment: Decimal.new("0.0001"),
                   quote_asset_precision: 8,
                   min_notional: Decimal.from_float(0.001)
                 },
                 Decimal.new("1"),
                 Decimal.new("1"),
                 client_order_id
               )
             )
  end

  # Converts a string |-delimited FIX message to a binary message delimited with soh (1)
  defp str_message_to_binary(str_message) do
    str_message
    |> :binary.split("|", [:global])
    |> Enum.join(<<1>>)
  end

  # defp binary_to_str_message(binary_msg) do
  #   binary_msg
  #   |> :binary.split(<<1>>, [:global])
  #   |> Enum.join("|")
  # end

  # create pair
  def pair(tag, value) do
    "#{tag}=#{value}"
  end
end
