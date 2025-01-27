defmodule OpportunityWatcher.OpportunityTest do
  @moduledoc "Tests for Opportunity"

  alias OpportunityWatcher.Opportunity
  alias Types.TradingSymbol

  use ExUnit.Case, async: true
  doctest Opportunity

  test "correct profit and capacity with 2 symbols" do
    commission = Decimal.new(0)

    path = [
      %TradingSymbol{symbol: "BTCUSDT", position: :long, base_asset: "BTC", quote_asset: "USDT"},
      %TradingSymbol{symbol: "USDTBTC", position: :long, base_asset: "USDT", quote_asset: "BTC"}
    ]

    price_table = %{
      %TradingSymbol{symbol: "BTCUSDT", position: :long, base_asset: "BTC", quote_asset: "USDT"} =>
        {Decimal.new("10000.0"), Decimal.new("1.0")},
      %TradingSymbol{symbol: "USDTBTC", position: :long, base_asset: "USDT", quote_asset: "BTC"} =>
        {Decimal.new("0.00005"), Decimal.new("1337.1337")},
      %TradingSymbol{symbol: "ETHBTC", position: :long, base_asset: "ETH", quote_asset: "BTC"} =>
        {Decimal.new("0.1"), Decimal.new("10.0")},
      %TradingSymbol{symbol: "USDTETH", position: :long, base_asset: "USDT", quote_asset: "ETH"} =>
        {Decimal.new("0.001"), Decimal.new("1.0")}
    }

    profit = Opportunity.profit(path, price_table, commission)
    capacity = Opportunity.capacity(path, price_table)

    assert Decimal.eq?(profit, 1)
    assert Decimal.eq?(capacity, Decimal.div(Decimal.new("1337.1337"), Decimal.add(1, profit)))
  end

  test "correct profit and capacity with 2 symbols (long + short)" do
    commission = Decimal.new(0)

    path = [
      %TradingSymbol{symbol: "BTCUSDT", position: :long, base_asset: "BTC", quote_asset: "USDT"},
      %TradingSymbol{symbol: "BTCUSDT", position: :short, base_asset: "USDT", quote_asset: "BTC"}
    ]

    price_table = %{
      %TradingSymbol{symbol: "BTCUSDT", position: :long, base_asset: "BTC", quote_asset: "USDT"} =>
        {Decimal.new("1.0"), Decimal.new("1.0")},
      %TradingSymbol{symbol: "BTCUSDT", position: :short, base_asset: "USDT", quote_asset: "BTC"} =>
        {Decimal.div(Decimal.new("1"), Decimal.new("2")), Decimal.new("1.0")}
    }

    profit = Opportunity.profit(path, price_table, commission)
    capacity = Opportunity.capacity(path, price_table)

    assert Decimal.eq?(profit, 1)
    assert Decimal.eq?(capacity, "0.5")
  end

  test "correct profit and capacity with 3 symbols" do
    commission = Decimal.new("0.01")

    path = [
      %TradingSymbol{symbol: "BTCUSDT", position: :long, base_asset: "BTC", quote_asset: "USDT"},
      %TradingSymbol{symbol: "ETHBTC", position: :long, base_asset: "ETH", quote_asset: "BTC"},
      %TradingSymbol{symbol: "USDTETH", position: :long, base_asset: "USDT", quote_asset: "ETH"}
    ]

    price_table = %{
      %TradingSymbol{symbol: "BTCUSDT", position: :long, base_asset: "BTC", quote_asset: "USDT"} =>
        {Decimal.new("10000"), Decimal.new("1.0")},
      %TradingSymbol{symbol: "ETHBTC", position: :long, base_asset: "ETH", quote_asset: "BTC"} =>
        {Decimal.new("0.1"), Decimal.new("10")},
      %TradingSymbol{symbol: "USDTETH", position: :long, base_asset: "USDT", quote_asset: "ETH"} =>
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
          %TradingSymbol{
            symbol: "BTCUSDT",
            position: :long,
            base_asset: "BTC",
            quote_asset: "USDT"
          },
          %TradingSymbol{
            symbol: "ETHBTC",
            position: :long,
            base_asset: "ETH",
            quote_asset: "BTC"
          },
          %TradingSymbol{
            symbol: "USDTETH",
            position: :long,
            base_asset: "USDT",
            quote_asset: "ETH"
          }
        ],
        %{
          %TradingSymbol{
            symbol: "BTCUSDT",
            position: :long,
            base_asset: "BTC",
            quote_asset: "USDT"
          } => {Decimal.new("10000"), Decimal.new("1.0")},
          %TradingSymbol{symbol: "ETHBTC", position: :long, base_asset: "ETH", quote_asset: "BTC"} =>
            {Decimal.new("0.1"), Decimal.new("10")}
        },
        Decimal.new("0.01")
      )
    end
  end
end
