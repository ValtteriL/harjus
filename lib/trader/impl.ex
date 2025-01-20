defmodule Trader.Impl do
  @moduledoc """
  Implementation for trader
  """

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
  def execute_opportunity(opportunity) do
    Logger.info("Executing opportunity: #{inspect(opportunity)}")

    pairs = opportunity.path |> Enum.map(& &1.symbol)

    # reserve the trading pairs
    reserve_symbols(pairs)

    execute_opportunity_after_reserving_symbols(opportunity)

    :ok
  end

  defp execute_opportunity_after_reserving_symbols(opportunity) do
    # reserve budget
    budget = Balance.reserve_upto(opportunity.path[0].quote_asset, opportunity.capacity)

    if Decimal.eq?(budget, 0) do
      raise "No budget available to reserve"
    end

    execute_opportunity_after_reserving_budget(opportunity, budget)
  end

  defp execute_opportunity_after_reserving_budget(opportunity, budget) do
    # execute trades
    balance_delta = trade(opportunity.path, budget)

    # update balances
    balance_delta |> Enum.each(&Balance.update(&1, balance_delta[&1]))
  end

  @spec trade([TradingSymbol.t()], Decimal.t()) :: balance_delta()
  defp trade(path, quantity) do
    trade(path, quantity, %{})
  end

  defp trade([trading_symbol | rest], quantity, balance_delta) do
    Logger.debug("Trading #{trading_symbol.symbol}")

    report = TradeClient.market_order(trading_symbol, quantity)
    Logger.debug(report)

    # update fee balance right away
    Balance.update(report.fee_currency, Decimal.negate(report.quantity_fee))

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
  defp update_balance_delta(delta, trading_symbol, trade_report) do
    delta
    # received
    |> Map.update(
      trading_symbol.base_asset,
      received_quantity(trade_report),
      &Decimal.add(&1, received_quantity(trade_report))
    )
    # used
    |> Map.update(
      trading_symbol.quote_asset,
      used_quantity(trade_report),
      &Decimal.sub(&1, used_quantity(trade_report))
    )
  end

  defp reserve_symbols(pairs) do
    pairs
    |> Enum.each(&Mutex.lock!(ReservedSymbols, &1))
  end
end
