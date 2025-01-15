defmodule Trader.Impl do
  @moduledoc """
  Implementation for trader
  """

  alias Types.Opportunity
  alias Types.TradeReport
  alias Types.TradingSymbol
  require Logger

  @doc """
  Create initial state
  """
  def new, do: :does_not_matter

  @doc """
  Execute opportunity
  """
  @spec execute_opportunity(opportunity :: Opportunity.t()) :: :ok
  def execute_opportunity(opportunity) do
    Logger.info("Executing opportunity: #{inspect(opportunity)}")

    # TODO: make reservation atomic - if one fails, release all
    # TODO: PM cannot do reservation because it does not react to demand but just shoots out opportunities

    # reserve the symbols
    reserve_symbols(opportunity.path)

    # execute the trades
    trade(opportunity.path, opportunity.quantity)

    # release the symbols
    release_symbols(opportunity.path)

    :ok
  end

  @spec trade([TradingSymbol.t()], float()) :: :ok
  defp trade([trading_symbol | rest], quantity) do
    Logger.debug("Trading #{trading_symbol.symbol}")

    report = TradeClient.market_order(trading_symbol, quantity)
    Logger.debug(report)

    update_balances(trading_symbol, report)

    # continue with the next trade using the money from the previous
    trade(rest, received_quantity(report))
  end

  defp trade([], _), do: :ok

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

  @spec update_balances(TradingSymbol.t(), TradeReport.t()) :: :ok
  defp update_balances(trading_symbol, trade_report) do
    # received, used, fee
    Balance.update(trading_symbol.base_asset, received_quantity(trade_report))
    Balance.update(trading_symbol.quote_asset, -used_quantity(trade_report))
    Balance.update(trade_report.fee_currency, -trade_report.quantity_fee)
  end

  defp reserve_symbols([trading_symbol | rest]) do
    ReservedSymbols.reserve(trading_symbol.symbol)
    reserve_symbols(rest)
  end

  defp reserve_symbols([]), do: :ok

  defp release_symbols([trading_symbol | rest]) do
    ReservedSymbols.release(trading_symbol.symbol)
    release_symbols(rest)
  end

  defp release_symbols([]), do: :ok
end
