defmodule Trader.Impl do
  @moduledoc """
  Implementation for trader
  """

  alias Trader.Balance, as: MyBalance
  alias Trader.BalanceDelta
  alias Trader.TradeClient
  alias Types.PlannedExecution
  alias Types.PlannedTrade
  alias Types.TradeReport
  alias Types.TradingSymbol
  require Logger

  @type balance_delta() :: %{String.t() => Decimal.t()}

  @spec execute(PlannedExecution.t()) :: %{String.t() => Decimal.t()}
  def execute(planned_execution) do
    debug("Executing: #{inspect(planned_execution)}")

    # execute trades
    balance_delta =
      case trade(planned_execution.trades) do
        {:expired, delta} ->
          warn("Failed execution. Balance delta: #{inspect(delta)}")
          Metrics.report_trade_failed()
          delta

        {:execution, delta} ->
          notice("Successful execution. Balance delta: #{inspect(delta)}")
          Metrics.report_trade_executed()
          delta
      end

    # add reserved budget back to balance, to get correct amount to release
    used_asset = used_asset(Enum.at(planned_execution.trades, 0).trading_symbol)
    used_qty = used_qty(Enum.at(planned_execution.trades, 0).trading_symbol)

    releasable_delta =
      BalanceDelta.increment_balance_delta(balance_delta, used_asset, used_qty)

    # return delta that can be released as is
    releasable_delta
  end

  @spec trade([PlannedTrade.t()]) ::
          {:execution, balance_delta()} | {:expired, balance_delta()}
  defp trade(path = [%PlannedTrade{} | _])
       when is_list(path) do
    trade(path, BalanceDelta.new())
  end

  @spec trade([PlannedTrade.t()], balance_delta()) ::
          {:execution, balance_delta()} | {:expired, balance_delta()}
  defp trade(
         [
           %PlannedTrade{trading_symbol: trading_symbol, order_qty: qty, order_price: price}
           | rest
         ],
         balance_delta
       ) do
    debug("Trading #{qty} of #{trading_symbol.symbol} at #{price}")

    case TradeClient.limit_order(trading_symbol, qty, price) do
      {:executed, report} ->
        debug("Trade completed. #{inspect(report)}")

        # update fee balance right away
        Enum.each(report.fees, fn %TradeReport.Fee{fee_currency: currency, fee_amount: amount} ->
          MyBalance.reserve!(currency, amount)
        end)

        new_balance_delta =
          BalanceDelta.update_balance_delta(balance_delta, trading_symbol, report)

        # continue with the next trade
        trade(rest, new_balance_delta)

      {:expired, _} ->
        debug("Trade expired.")
        {:expired, balance_delta}
    end
  end

  defp trade([], balance_delta), do: {:execution, balance_delta}

  defp used_asset(%TradingSymbol{position: :long, quote_asset: q}), do: q
  defp used_asset(%TradingSymbol{position: :short, base_asset: b}), do: b
  defp used_qty(%TradingSymbol{position: :long, qty: q, price: p}), do: Decimal.mult(q, p)
  defp used_qty(%TradingSymbol{position: :short, qty: q}), do: q

  defp notice(msg) do
    Logger.notice("#{:erlang.pid_to_list(self())}: #{msg}")
  end

  defp debug(msg) do
    Logger.debug("#{:erlang.pid_to_list(self())}: #{msg}")
  end

  defp warn(msg) do
    Logger.warning("#{:erlang.pid_to_list(self())}: #{msg}")
  end
end
