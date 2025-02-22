defmodule Trader.Impl do
  @moduledoc """
  Implementation for trader
  """

  alias Trader.Balance, as: MyBalance
  alias Trader.Error.InsufficientBalanceError
  alias Trader.Error.SymbolAlreadyReservedError
  alias Trader.TradeClient
  alias Types.Opportunity
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
    Logger.debug("Attempting execution with: #{inspect(opportunity)}")
    Metrics.report_trade_attempted()

    pairs = path |> Enum.map(& &1.symbol)

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
        Enum.at(opportunity.path, 0).quote_asset,
        opportunity.capacity,
        Enum.at(opportunity.path, 0).quote_asset_increment,
        Enum.at(opportunity.path, 0).quote_asset_precision
      )

    if Decimal.eq?(budget, 0) do
      # release the trading pairs (required to make tests work, as they dont use separate process)
      Mutex.goodbye(ReservedSymbols)

      raise InsufficientBalanceError
    end

    execute_opportunity_after_reserving_budget(opportunity, budget)
  end

  defp execute_opportunity_after_reserving_budget(opportunity, budget) do
    Logger.notice("Executing opportunity #{inspect(opportunity)} with budget: #{budget}")

    # execute trades
    balance_delta = trade(opportunity.path, budget)

    Logger.notice(
      "Opportunity #{inspect(opportunity)} executed successfully. Balance delta: #{inspect(balance_delta)}"
    )

    Metrics.report_trade_executed()
    Metrics.report_trade_report_delta(balance_delta)

    starting_balance_delta =
      Decimal.to_float(balance_delta[Enum.at(opportunity.path, 0).quote_asset])

    case starting_balance_delta do
      x when x > 0 -> Metrics.report_trade_winning()
      _ -> Metrics.report_trade_losing()
    end

    # update balances
    balance_delta
    |> Enum.each(fn {symbol, qty_change} -> MyBalance.update(symbol, qty_change) end)
  end

  @spec trade([TradingSymbol.t()], Decimal.t()) :: balance_delta()
  defp trade(path = [%TradingSymbol{quote_asset: quote_asset} | _], quantity) do
    trade(path, quantity, %{quote_asset => quantity})
  end

  defp trade([trading_symbol | rest], quantity, balance_delta) do
    Logger.debug("Trading #{inspect(trading_symbol)} with quantity: #{inspect(quantity)}")
    report = TradeClient.market_order(trading_symbol, quantity)
    Logger.debug("Trade #{inspect(trading_symbol)} completed. Report: #{inspect(report)}")

    # update fee balance right away
    Enum.each(report.fees, fn %TradeReport.Fee{fee_currency: currency, fee_amount: amount} ->
      MyBalance.update(currency, Decimal.negate(amount))
    end)

    # store other balance changes in delta
    new_balance_delta = update_balance_delta(balance_delta, trading_symbol, report)

    # continue with the next trade using the money from the previous
    trade(rest, received_quantity(report), new_balance_delta)
  end

  defp trade([], _, balance_delta), do: balance_delta

  defp received_quantity(trade_report) do
    case trade_report.position do
      :long -> trade_report.quantity_base
      :short -> trade_report.quantity_quote
    end
  end

  defp used_quantity(trade_report) do
    case trade_report.position do
      :long -> trade_report.quantity_quote
      :short -> trade_report.quantity_base
    end
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
end
