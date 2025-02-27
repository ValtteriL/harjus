defmodule Trader.Impl do
  @moduledoc """
  Implementation for trader
  """

  alias Trader.Balance, as: MyBalance
  alias Trader.Error.InsufficientBalanceError
  alias Trader.Error.SymbolAlreadyReservedError
  alias Trader.TradeClient
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
    # reserve budget
    budget =
      MyBalance.reserve_upto(
        Enum.at(opportunity.path, 0).trading_symbol.quote_asset,
        opportunity.capacity,
        # wrong - should be quote asset increment, same for precision - remove altogether?
        Enum.at(opportunity.path, 0).trading_symbol.base_asset_increment,
        Enum.at(opportunity.path, 0).trading_symbol.base_asset_precision
      )

    if Decimal.eq?(budget, 0) do
      # release the trading pairs (required to make tests work, as they dont use separate process)
      Mutex.goodbye(ReservedSymbols)

      raise InsufficientBalanceError
    end

    execute_opportunity_after_reserving_budget(opportunity, budget)
  end

  defp execute_opportunity_after_reserving_budget(opportunity, budget) do
    notice("Executing opportunity #{inspect(opportunity)} with budget: #{budget}")

    # execute trades
    balance_delta =
      case trade(opportunity.path, budget) do
        {:canceled, balance_delta} ->
          warn("Failed execution. Balance delta: #{inspect(balance_delta)}")
          Metrics.report_trade_failed()
          balance_delta

        {:execution, balance_delta} ->
          notice("Successful execution. Balance delta: #{inspect(balance_delta)}")

          Metrics.report_trade_executed()

          starting_balance_delta =
            Decimal.to_float(
              balance_delta[Enum.at(opportunity.path, 0).trading_symbol.quote_asset]
            )

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
  defp trade(
         path = [%PlannedTrade{trading_symbol: %TradingSymbol{quote_asset: quote_asset}} | _],
         budget
       ) do
    trade(path, budget, %{quote_asset => budget})
  end

  defp trade(
         [
           %PlannedTrade{trading_symbol: trading_symbol, order_price: price}
           | rest
         ],
         budget,
         balance_delta
       ) do
    # calculate how many we can buy with the budget
    qty = order_qty_for_budget(budget, price, trading_symbol)

    case TradeClient.limit_order(trading_symbol, qty, price) do
      {:executed, report} ->
        debug("Trade completed. #{inspect(trading_symbol)}")

        # update fee balance right away
        Enum.each(report.fees, fn %TradeReport.Fee{fee_currency: currency, fee_amount: amount} ->
          MyBalance.update(currency, Decimal.negate(amount))
        end)

        # store other balance changes in delta
        new_balance_delta = update_balance_delta(balance_delta, trading_symbol, report)

        # continue with the next trade using the money from the previous
        trade(rest, received_quantity(report), new_balance_delta)

      {:canceled, _} ->
        debug("Trade canceled. #{inspect(trading_symbol)}")
        {:canceled, balance_delta}
    end
  end

  defp trade([], _, balance_delta), do: {:execution, balance_delta}

  defp received_quantity(trade_report) do
    trade_report.quantity_base
  end

  defp used_quantity(trade_report) do
    trade_report.quantity_quote
  end

  @spec update_balance_delta(balance_delta(), TradingSymbol.t(), TradeReport.t()) ::
          balance_delta()
  defp update_balance_delta(
         delta,
         %TradingSymbol{base_asset: base_asset, quote_asset: quote_asset},
         trade_report
       ) do
    delta
    # received
    |> Map.update(
      base_asset,
      received_quantity(trade_report),
      fn current_qty -> Decimal.add(current_qty, received_quantity(trade_report)) end
    )
    # used
    |> Map.update!(
      quote_asset,
      fn current_qty -> Decimal.sub(current_qty, used_quantity(trade_report)) end
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

  defp order_qty_for_budget(budget, price, trading_symbol) do
    Decimal.div(budget, price)
    |> Decimal.div_int(trading_symbol.base_asset_increment)
    |> Decimal.mult(trading_symbol.base_asset_increment)
  end

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
