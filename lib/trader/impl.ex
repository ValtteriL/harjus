defmodule Trader.Impl do
  @moduledoc """
  Implementation for trader
  """

  alias Trader.Balance, as: MyBalance
  alias Trader.Error.SymbolAlreadyReservedError
  alias Trader.TradeClient
  alias Types.Opportunity
  alias Types.PlannedTrade
  alias Types.TradeReport
  alias Types.TradingSymbol
  require Logger
  import Decimal

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
          MyBalance.reserve_upto(
            first_ts.quote_asset,
            opportunity.capacity,
            first_ts.quote_asset_increment,
            first_ts.quote_asset_precision
          )

        :short ->
          MyBalance.reserve_upto(
            first_ts.base_asset,
            opportunity.capacity,
            first_ts.base_asset_increment,
            first_ts.base_asset_precision
          )
      end

    case plan_execution(opportunity, budget) do
      {:ok, plan} ->
        notice("Executing opportunity #{inspect(opportunity)} with budget: #{budget}")
        execute_plan(plan, budget)

      {:insufficient_balance, _} ->
        debug("Insufficient balance for opportunity #{inspect(opportunity)}")
        MyBalance.update(used_asset(first_ts), budget)
    end
  end

  defp execute_plan(plan = [%PlannedTrade{} | _], reserved_budget) do
    # execute trades
    balance_delta =
      case trade(plan, reserved_budget) do
        {:canceled, balance_delta} ->
          warn("Failed execution. Balance delta: #{inspect(balance_delta)}")
          Metrics.report_trade_failed()
          balance_delta

        {:execution, balance_delta} ->
          notice("Successful execution. Balance delta: #{inspect(balance_delta)}")

          Metrics.report_trade_executed()

          starting_balance_delta =
            Decimal.to_float(balance_delta[used_asset(Enum.at(plan, 0).trading_symbol)])

          case starting_balance_delta do
            x when x > 0 -> Metrics.report_trade_winning()
            _ -> Metrics.report_trade_losing()
          end

          balance_delta
      end

    Metrics.report_trade_report_delta(balance_delta)

    # update balances
    balance_delta
    |> Enum.each(fn {symbol, qty_change} -> MyBalance.update(symbol, qty_change) end)
  end

  @spec trade([PlannedTrade.t()], Decimal.t()) ::
          {:execution, balance_delta()} | {:canceled, balance_delta()}
  defp trade(path = [%PlannedTrade{trading_symbol: ts} | _], reserved_budget)
       when is_list(path) and is_decimal(reserved_budget) do
    used_asset = used_asset(ts)
    # Todo
    trade(path, %{used_asset => reserved_budget})
  end

  defp trade(
         [
           %PlannedTrade{trading_symbol: trading_symbol, order_qty: qty, order_price: price}
           | rest
         ],
         balance_delta
       ) do
    case TradeClient.limit_order(trading_symbol, qty, price) do
      {:executed, report} ->
        debug("Trade completed. #{inspect(report)}")

        # update fee balance right away
        Enum.each(report.fees, fn %TradeReport.Fee{fee_currency: currency, fee_amount: amount} ->
          MyBalance.update(currency, Decimal.negate(amount))
        end)

        # store other balance changes in delta
        new_balance_delta = update_balance_delta(balance_delta, trading_symbol, report)

        # continue with the next trade
        trade(rest, new_balance_delta)

      {:canceled, _} ->
        debug("Trade canceled.")
        {:canceled, balance_delta}

      result ->
        raise "Unexpected trade result: #{inspect(result)}"
    end
  end

  defp trade([], balance_delta), do: {:execution, balance_delta}

  @spec update_balance_delta(balance_delta(), TradingSymbol.t(), TradeReport.t()) ::
          balance_delta()
  defp update_balance_delta(
         delta,
         %TradingSymbol{base_asset: base_asset, quote_asset: quote_asset},
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
      trade_report.quantity_quote,
      fn current_qty -> Decimal.add(current_qty, trade_report.quantity_quote) end
    )
  end

  defp reserve_symbols(pairs) do
    pairs
    |> Enum.each(fn pair ->
      case Mutex.lock(ReservedSymbols, pair) do
        {:ok, _} -> :ok
        _ -> raise SymbolAlreadyReservedError
      end
    end)
  end

  @spec plan_execution(Opportunity.t(), Decimal.t()) ::
          {:ok, [PlannedTrade.t()]} | {:insufficient_balance, any()}
  defp plan_execution(
         %Opportunity{
           path: path = [%PlannedTrade{} | _],
           capacity: full_capacity
         },
         budget
       ) do
    # plan valid qty, price for each trade in opportunity based on budget
    capacity = Decimal.min(full_capacity, budget)

    plan =
      path
      |> Enum.map_reduce(capacity, fn pt, acc ->
        order_qty = order_qty_for_budget(acc, pt.order_price, pt.trading_symbol)

        {
          %PlannedTrade{
            trading_symbol: pt.trading_symbol,
            order_price: pt.order_price,
            order_qty: order_qty
          },
          order_qty
        }
      end)
      |> elem(0)

    # ensure all trades have notional >= min_notional
    notional_fulfilled =
      plan
      |> Enum.all?(fn pt ->
        notional = Decimal.mult(pt.order_qty, pt.order_price)
        Decimal.lt?(notional, pt.trading_symbol.min_notional)
      end)

    if notional_fulfilled do
      {:ok, plan}
    else
      {:insufficient_balance, nil}
    end
  end

  # ensure qty is a multiple of base_asset_increment
  defp order_qty_for_budget(budget, price, trading_symbol) do
    Decimal.div(budget, price)
    |> Decimal.div_int(trading_symbol.base_asset_increment)
    |> Decimal.mult(trading_symbol.base_asset_increment)
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
end
