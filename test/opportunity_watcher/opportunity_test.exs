defmodule OpportunityWatcher.OpportunityTest do
  @moduledoc "Tests for Opportunity"

  alias OpportunityWatcher.Opportunity
  alias Types.TradingSymbol

  use ExUnit.Case, async: true
  doctest Opportunity
  use PropCheck

  property "profit cannot be less than -1" do
    forall [{trading_path, price_qty_map}, commission_percentage] <- [
             trading_path_and_price_map(),
             float(0.0, 1.0)
           ] do
      commission = Decimal.from_float(commission_percentage)

      profit =
        Opportunity.profit(trading_path, price_qty_map, commission)

      # profit cannot be less than -1
      assert Decimal.gte?(profit, -1)
    end
  end

  property "capacity is always greater than or equal to 0" do
    forall {trading_path, price_qty_map} <- trading_path_and_price_map() do
      capacity = Opportunity.capacity(trading_path, price_qty_map)

      # capacity is always greater than or equal to 0
      assert Decimal.gte?(capacity, 0)
    end
  end

  property "plan_trades contains same number of trades as trading path" do
    forall {trading_path, price_qty_map} <- trading_path_and_price_map() do
      capacity = Opportunity.capacity(trading_path, price_qty_map)
      trades = Opportunity.plan_trades(trading_path, capacity, price_qty_map)

      # plan_trades contains same number of trades as trading path
      assert length(trades) == length(trading_path)
    end
  end

  property "plan_trades first order_qty is always lte capacity" do
    forall {trading_path, price_qty_map} <- trading_path_and_price_map() do
      capacity = Opportunity.capacity(trading_path, price_qty_map)
      trades = Opportunity.plan_trades(trading_path, capacity, price_qty_map)

      # required qty for first trade is lte capacity
      first_trade = Enum.at(trades, 0)

      case first_trade.trading_symbol do
        %TradingSymbol{position: :long} ->
          assert Decimal.lte?(
                   Decimal.mult(first_trade.order_qty, first_trade.order_price),
                   capacity
                 )

        %TradingSymbol{position: :short} ->
          assert Decimal.lte?(first_trade.order_qty, capacity)
      end
    end
  end

  property "quantities in plan_trades are always positive" do
    forall {trading_path, price_qty_map} <- trading_path_and_price_map() do
      capacity = Opportunity.capacity(trading_path, price_qty_map)
      trades = Opportunity.plan_trades(trading_path, capacity, price_qty_map)

      # quantities in plan_trades are always positive
      assert Enum.all?(trades, fn trade -> Decimal.gte?(trade.order_qty, 0) end)
    end
  end

  property "quantities in plan_trades are always multiples of base_asset_increment" do
    forall {trading_path, price_qty_map} <- trading_path_and_price_map() do
      capacity = Opportunity.capacity(trading_path, price_qty_map)
      trades = Opportunity.plan_trades(trading_path, capacity, price_qty_map)

      # quantities in plan_trades are always multiples of base_asset_increment
      assert Enum.all?(trades, fn trade ->
               Decimal.eq?(
                 Decimal.rem(trade.order_qty, trade.trading_symbol.base_asset_increment),
                 0
               )
             end)
    end
  end

  ## Generators ##

  defp trading_path_and_price_map do
    let trading_path <- non_empty(list(trading_symbol())) do
      let price_qty_tuples <- non_empty(list(price_qty_tuple())) do
        # limit to at most 10 hops, as more unrealistic and will cause divisions by zero
        let price_qty_map <-
              Enum.zip(Enum.take(trading_path, 10), price_qty_tuples)
              |> Enum.into(%{}) do
          {elem(Enum.unzip(price_qty_map), 0), price_qty_map}
        end
      end
    end
  end

  defp price_qty_tuple do
    let [price <- non_neg_float(), qty <- non_neg_float()] do
      {Decimal.from_float(price), Decimal.from_float(qty)}
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

  def non_empty_string do
    let charlist <- non_empty(elements(textdata())) do
      to_string(charlist)
    end
  end

  defp textdata do
    ~c"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789" ++
      ~c":;<=>?@ !#$%&'()*+-./[\\]^_`{|}~"
  end

  ## Unit tests ##

  test "capacity is 0 if min_notional is not met" do
    symbol = %TradingSymbol{
      symbol: "BTCUSDT",
      position: :long,
      base_asset: "BTC",
      quote_asset: "USDT",
      base_asset_increment: Decimal.from_float(0.01),
      base_asset_precision: 8,
      quote_asset_increment: Decimal.from_float(0.01),
      quote_asset_precision: 8,
      min_notional: Decimal.new(2)
    }

    path = [
      symbol
    ]

    price_table = %{
      # price, qty
      # min_notional not met
      symbol => {Decimal.new(1), Decimal.div(symbol.min_notional, 2)}
    }

    capacity = Opportunity.capacity(path, price_table)
    assert Decimal.eq?(capacity, 0)
  end

  test "profit and capacity 0 if price is 0" do
    commission = Decimal.new(0)
    symbol = ts(%{symbol: "BTCUSDT", position: :long, base_asset: "BTC", quote_asset: "USDT"})

    path = [
      symbol
    ]

    price_table = %{
      # price, qty
      symbol => {Decimal.new(0), Decimal.new(1)}
    }

    profit = Opportunity.profit(path, price_table, commission)
    capacity = Opportunity.capacity(path, price_table)

    assert Decimal.eq?(profit, 0)
    assert Decimal.eq?(capacity, 0)
  end

  test "correct profit and capacity with 2 symbols" do
    commission = Decimal.new(0)

    path = [
      ts(%{symbol: "BTCUSDT", position: :long, base_asset: "BTC", quote_asset: "USDT"}),
      ts(%{symbol: "USDTBTC", position: :long, base_asset: "USDT", quote_asset: "BTC"})
    ]

    price_table = %{
      ts(%{symbol: "BTCUSDT", position: :long, base_asset: "BTC", quote_asset: "USDT"}) =>
        {Decimal.new("10000.0"), Decimal.new("1.0")},
      ts(%{symbol: "USDTBTC", position: :long, base_asset: "USDT", quote_asset: "BTC"}) =>
        {Decimal.new("0.00005"), Decimal.new("1337.1337")}
    }

    profit = Opportunity.profit(path, price_table, commission)
    capacity = Opportunity.capacity(path, price_table)

    assert Decimal.eq?(profit, 1)
    assert Decimal.eq?(capacity, 1)
  end

  test "correct profit and capacity with 2 symbols (long + short)" do
    commission = Decimal.new(0)

    path = [
      ts(%{symbol: "BTCUSDT", position: :long, base_asset: "BTC", quote_asset: "USDT"}),
      ts(%{symbol: "BTCUSDT", position: :short, base_asset: "BTC", quote_asset: "USDT"})
    ]

    price_table = %{
      ts(%{symbol: "BTCUSDT", position: :long, base_asset: "BTC", quote_asset: "USDT"}) =>
        {Decimal.new("1.0"), Decimal.new("1.0")},
      ts(%{symbol: "BTCUSDT", position: :short, base_asset: "BTC", quote_asset: "USDT"}) =>
        {Decimal.new("2.0"), Decimal.new("1.0")}
    }

    profit = Opportunity.profit(path, price_table, commission)
    capacity = Opportunity.capacity(path, price_table)

    assert Decimal.eq?(profit, 1)
    assert Decimal.eq?(capacity, 1)
  end

  test "correct profit and capacity with 3 symbols" do
    commission = Decimal.new("0.01")

    path = [
      ts(%{symbol: "BTCUSDT", position: :long, base_asset: "BTC", quote_asset: "USDT"}),
      ts(%{symbol: "ETHBTC", position: :long, base_asset: "ETH", quote_asset: "BTC"}),
      ts(%{symbol: "USDTETH", position: :long, base_asset: "USDT", quote_asset: "ETH"})
    ]

    price_table = %{
      ts(%{symbol: "BTCUSDT", position: :long, base_asset: "BTC", quote_asset: "USDT"}) =>
        {Decimal.new("10000"), Decimal.new("1.0")},
      ts(%{symbol: "ETHBTC", position: :long, base_asset: "ETH", quote_asset: "BTC"}) =>
        {Decimal.new("0.1"), Decimal.new("10")},
      ts(%{symbol: "USDTETH", position: :long, base_asset: "USDT", quote_asset: "ETH"}) =>
        {Decimal.new("0.001"), Decimal.new("1.0")}
    }

    profit = Opportunity.profit(path, price_table, commission)
    capacity = Opportunity.capacity(path, price_table)

    assert Decimal.eq?(profit, Decimal.sub(pow(Decimal.sub(1, commission), length(path)), 1))
    assert Decimal.eq?(capacity, Decimal.new("1.0"))
  end

  defp pow(x, n) do
    Enum.reduce(1..(n - 1), x, fn _, acc -> Decimal.mult(acc, x) end)
  end

  test "missing symbol in pricing results in ArgumentError" do
    assert_raise ArgumentError, fn ->
      Opportunity.profit(
        [
          ts(%{
            symbol: "BTCUSDT",
            position: :long,
            base_asset: "BTC",
            quote_asset: "USDT"
          }),
          ts(%{
            symbol: "ETHBTC",
            position: :long,
            base_asset: "ETH",
            quote_asset: "BTC"
          }),
          ts(%{
            symbol: "USDTETH",
            position: :long,
            base_asset: "USDT",
            quote_asset: "ETH"
          })
        ],
        %{
          ts(%{
            symbol: "BTCUSDT",
            position: :long,
            base_asset: "BTC",
            quote_asset: "USDT"
          }) => {Decimal.new("10000"), Decimal.new("1.0")},
          ts(%{symbol: "ETHBTC", position: :long, base_asset: "ETH", quote_asset: "BTC"}) =>
            {Decimal.new("0.1"), Decimal.new("10")}
        },
        Decimal.new("0.01")
      )
    end
  end

  defp ts(%{symbol: symbol, position: position, base_asset: base_aset, quote_asset: quote_asset}) do
    %TradingSymbol{
      symbol: symbol,
      position: position,
      base_asset: base_aset,
      quote_asset: quote_asset,
      base_asset_increment: Decimal.new("0.01"),
      base_asset_precision: 8,
      quote_asset_increment: Decimal.new("0.01"),
      quote_asset_precision: 8,
      min_notional: Decimal.from_float(0.0001)
    }
  end
end
