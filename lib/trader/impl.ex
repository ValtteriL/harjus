defmodule Trader.Impl do
  @moduledoc """
  Implementation for trader
  """

  alias Trader.Balance, as: MyBalance
  alias Trader.BalanceDelta
  alias Trader.Error.SymbolAlreadyReservedError
  alias Trader.TradeClient
  alias Trader.TradePlanner
  alias Types.Opportunity
  alias Types.PlannedTrade
  alias Types.TradeReport
  alias Types.TradingSymbol
  require Logger

  @type balance_delta() :: %{String.t() => Decimal.t()}

  @doc """
  Create initial state
  """
  def new do
    Mutex.start_link(name: ReservedSymbols)
    TradeClient.new()
    :does_not_matter
  end

  @doc """
  Execute opportunity
  """
  @spec execute_opportunity(opportunity :: Opportunity.t()) :: :ok
  def execute_opportunity(opportunity = %Opportunity{path: path}) when is_list(path) do
    debug("Attempting execution with: #{inspect(opportunity)}")

    Metrics.report_trade_attempted()

    pairs = path |> Enum.map(fn %PlannedTrade{trading_symbol: ts} -> ts.symbol end)

    # reserve the trading pairs
    reserve_symbols(pairs)

    execute_opportunity_after_reserving_symbols(opportunity)

    # release the trading pairs (required to make tests work, as they dont use separate process)
    Mutex.goodbye(ReservedSymbols)
    :ok
  end

  defp execute_opportunity_after_reserving_symbols(opportunity) do
    first_ts = Enum.at(opportunity.path, 0).trading_symbol

    # reserve budget
    budget =
      case first_ts.position do
        :long ->
          debug("Reserving budget for long position (asset #{first_ts.quote_asset})")

          MyBalance.reserve_upto(
            first_ts.quote_asset,
            opportunity.capacity,
            first_ts.quote_asset_increment,
            first_ts.quote_asset_precision
          )

        :short ->
          debug("Reserving budget for short position (asset #{first_ts.base_asset})")

          MyBalance.reserve_upto(
            first_ts.base_asset,
            opportunity.capacity,
            first_ts.base_asset_increment,
            first_ts.base_asset_precision
          )
      end

    case TradePlanner.plan_execution(opportunity, budget) do
      {:ok, plan} ->
        info("Executing opportunity #{inspect(plan)} with budget: #{budget}")
        execute_plan(plan, budget)

      {:insufficient_balance, _} ->
        debug("Insufficient balance (#{budget}) for opportunity #{inspect(opportunity)}")
        MyBalance.update(used_asset(first_ts), budget)
    end
  end

  defp execute_plan(plan = [%PlannedTrade{} | _], reserved_budget) do
    # execute trades
    balance_delta =
      case trade(plan) do
        {:expired, delta} ->
          warn("Failed execution. Balance delta: #{inspect(delta)}")
          Metrics.report_trade_failed()
          delta

        {:execution, delta} ->
          notice("Successful execution. Balance delta: #{inspect(delta)}")
          Metrics.report_trade_executed()
          delta
      end

    Metrics.report_trade_report_delta(balance_delta)

    # add reserved budget back to balance, to get correct amount to release
    used_asset = used_asset(Enum.at(plan, 0).trading_symbol)

    releasable_delta =
      BalanceDelta.increment_balance_delta(balance_delta, used_asset, reserved_budget)

    # update balances
    releasable_delta
    |> Enum.each(fn {symbol, qty_change} -> MyBalance.update(symbol, qty_change) end)
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
          MyBalance.update(currency, Decimal.negate(amount))
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

  defp reserve_symbols(pairs) do
    pairs
    |> Enum.each(fn pair ->
      case Mutex.lock(ReservedSymbols, pair) do
        {:ok, _} -> :ok
        _ -> raise SymbolAlreadyReservedError
      end
    end)
  end

  defp used_asset(%TradingSymbol{position: :long, quote_asset: q}), do: q
  defp used_asset(%TradingSymbol{position: :short, base_asset: b}), do: b

  defp notice(msg) do
    Logger.notice("#{:erlang.pid_to_list(self())}: #{msg}")
  end

  defp debug(msg) do
    Logger.debug("#{:erlang.pid_to_list(self())}: #{msg}")
  end

  defp warn(msg) do
    Logger.warning("#{:erlang.pid_to_list(self())}: #{msg}")
  end

  defp info(msg) do
    Logger.info("#{:erlang.pid_to_list(self())}: #{msg}")
  end
end
