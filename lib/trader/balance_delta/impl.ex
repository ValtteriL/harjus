defmodule Trader.BalanceDelta.Impl do
  @moduledoc """
  Balance delta implementation
  """

  alias Types.TradeReport
  alias Types.TradingSymbol

  @type balance_delta() :: %{String.t() => Decimal.t()}

  @spec update_balance_delta(balance_delta(), TradingSymbol.t(), TradeReport.t()) ::
          balance_delta()
  def update_balance_delta(
        delta,
        %TradingSymbol{base_asset: base_asset, quote_asset: quote_asset, position: :long},
        trade_report
      ) do
    delta
    # base
    |> Map.update(
      base_asset,
      trade_report.quantity_base,
      fn current_qty -> Decimal.add(current_qty, trade_report.quantity_base) end
    )
    # quote
    |> Map.update(
      quote_asset,
      Decimal.negate(trade_report.quantity_quote),
      fn current_qty -> Decimal.sub(current_qty, trade_report.quantity_quote) end
    )
  end

  def update_balance_delta(
        delta,
        %TradingSymbol{base_asset: base_asset, quote_asset: quote_asset, position: :short},
        trade_report
      ) do
    delta
    |> Map.update(
      base_asset,
      Decimal.negate(trade_report.quantity_base),
      fn current_qty -> Decimal.sub(current_qty, trade_report.quantity_base) end
    )
    |> Map.update(
      quote_asset,
      trade_report.quantity_quote,
      fn current_qty -> Decimal.add(current_qty, trade_report.quantity_quote) end
    )
  end
end
