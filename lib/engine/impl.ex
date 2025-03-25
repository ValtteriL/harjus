defmodule Engine.Impl do
  @moduledoc """
  Implementation of the engine
  """

  alias Types.PlannedExecution
  alias Types.TradingSymbol

  def new(trading_paths, commission, relative_asset_values) do
    port =
      Port.open(
        {:spawn, Application.get_env(:harjus, :path_to_port)},
        [:binary]
      )

    parameters = %{
      trading_paths: trading_paths,
      commission: commission,
      relative_asset_values: relative_asset_values
    }

    # send parameters to port
    send(port, {self(), {:command, Jason.encode!(parameters)}})
    send(port, {self(), {:command, "\n"}})

    %{port: port}
  end

  def price_update(state = %{port: port}, update) do
    Metrics.report_price_update()
    send(port, {self(), {:command, update}})
    send(port, {self(), {:command, "\n"}})
    state
  end

  # decode, relay opportunities to pipeline
  def relay_opportunities(state, msg) do
    opportunities = decode_opportunities(msg)
    Pipeline.handle_opportunities(opportunities)
    state
  end

  defp decode_opportunities(msg) do
    Jason.decode!(msg)
    |> Enum.map(fn x -> decode_planned_execution(x) end)
  end

  defp decode_planned_execution(%{"total_profit" => total_profit, "trades" => trades}) do
    %PlannedExecution{
      total_profit: Decimal.new(total_profit),
      trades: Enum.map(trades, fn x -> decode_trading_symbol(x) end)
    }
  end

  defp decode_trading_symbol(%{
         "symbol" => symbol,
         "position" => position,
         "base_asset" => base_asset,
         "quote_asset" => quote_asset,
         "base_asset_increment" => base_asset_increment,
         "base_asset_precision" => base_asset_precision,
         "quote_asset_increment" => quote_asset_increment,
         "quote_asset_precision" => quote_asset_precision,
         "min_notional" => min_notional,
         "qty" => qty,
         "price" => price
       }) do
    pos_atom =
      case position do
        "buy" -> :buy
        "sell" -> :sell
      end

    %TradingSymbol{
      symbol: symbol,
      position: pos_atom,
      base_asset: base_asset,
      quote_asset: quote_asset,
      base_asset_increment: Decimal.new(base_asset_increment),
      base_asset_precision: base_asset_precision,
      quote_asset_increment: Decimal.new(quote_asset_increment),
      quote_asset_precision: quote_asset_precision,
      min_notional: Decimal.new(min_notional),
      qty: Decimal.new(qty),
      price: Decimal.new(price)
    }
  end
end
