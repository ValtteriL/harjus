defmodule Evidence do
  budget = 6194.00000000

  evidence = [
    %Types.PlannedTrade{
      trading_symbol: %Types.TradingSymbol{
        symbol: "USDCUSDT",
        position: :short,
        base_asset: "USDC",
        quote_asset: "USDT",
        base_asset_increment: Decimal.new("1.00000000"),
        base_asset_precision: 8,
        quote_asset_increment: Decimal.new("0.00010000"),
        quote_asset_precision: 8,
        min_notional: Decimal.new("5.00000000")
      },
      order_qty: Decimal.new("6194.00000000"),
      order_price: Decimal.new("0.99970000")
    },

    # = 6194 USDC to 6 192,1418 USDT
    %Types.PlannedTrade{
      trading_symbol: %Types.TradingSymbol{
        symbol: "RAYUSDT",
        position: :long,
        base_asset: "RAY",
        quote_asset: "USDT",
        base_asset_increment: Decimal.new("0.10000000"),
        base_asset_precision: 8,
        quote_asset_increment: Decimal.new("0.00100000"),
        quote_asset_precision: 8,
        min_notional: Decimal.new("5.00000000")
      },
      order_qty: Decimal.new("2213.80000000"),
      order_price: Decimal.new("2.79700000")
    },

    # = 6 191,9986 USDT to 2213,8 RAY
    %Types.PlannedTrade{
      trading_symbol: %Types.TradingSymbol{
        symbol: "RAYUSDC",
        position: :short,
        base_asset: "RAY",
        quote_asset: "USDC",
        base_asset_increment: Decimal.new("0.10000000"),
        base_asset_precision: 8,
        quote_asset_increment: Decimal.new("0.00100000"),
        quote_asset_precision: 8,
        min_notional: Decimal.new("5.00000000")
      },
      order_qty: Decimal.new("2213.80000000"),
      order_price: Decimal.new("2.82600000")
    }

    # = 2213,8 RAY to 6 256,1988 USDC
  ]

  # start USDC = 6194
  # end USDC = 6 256,1988
  # end USDT = 6 192,1418 - 6 191,9986 = 0,1432
  # end RAY = 2213,8 - 2213,8 = 0

  balance_delta = %{
    # correct
    "RAY" => Decimal.new("0E-8"),
    # incorrect
    "USDC" => Decimal.new("-6260.62640000"),
    # incorrect
    "USDT" => Decimal.new("-12381.92660000")
  }
end
