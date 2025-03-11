defmodule Metrics.Impl do
  @moduledoc "Metrics implementation"

  import Telemetry.Metrics

  defp trading_symbol_count, do: [:harjus, :market_data, :trading_symbol]
  defp trading_path_count, do: [:harjus, :market_data, :trading_path]
  defp price_update, do: [:harjus, :price_streamer, :price_update]
  defp trade_executed, do: [:harjus, :trader, :trade, :executed]
  defp trade_failed, do: [:harjus, :trader, :trade, :failed]

  defp counter_measurement, do: :count

  @spec metrics() :: [
          Telemetry.Metrics.Counter.t()
          | Telemetry.Metrics.Summary.t()
          | Telemetry.Metrics.LastValue.t()
        ]
  def metrics do
    [
      # market data metrics
      last_value(
        trading_symbol_count(),
        event_name: trading_symbol_count(),
        measurement: counter_measurement(),
        description: "Number of trading symbols available in exchange"
      ),
      last_value(
        trading_path_count(),
        event_name: trading_path_count(),
        measurement: counter_measurement(),
        description: "Number of possible trading paths"
      ),

      # price streamer metrics
      counter(
        price_update(),
        event_name: price_update(),
        measurement: counter_measurement(),
        description: "Number of price updates received"
      ),

      # trader metrics
      counter(
        trade_executed(),
        event_name: trade_executed(),
        measurement: counter_measurement(),
        description: "Number of trades executed"
      ),
      counter(
        trade_failed(),
        event_name: trade_failed(),
        measurement: counter_measurement(),
        description: "Number of trades failed"
      ),

      # VM Metrics
      last_value("vm.memory.total", unit: :byte),
      last_value("vm.total_run_queue_lengths.total"),
      last_value("vm.total_run_queue_lengths.cpu"),
      last_value("vm.total_run_queue_lengths.io")
    ]
  end

  @spec report_trading_symbol_count(count :: integer()) :: :ok
  def report_trading_symbol_count(count) do
    :telemetry.execute(trading_symbol_count(), %{counter_measurement() => count})
  end

  @spec report_trading_path_count(count :: integer()) :: :ok
  def report_trading_path_count(count) do
    :telemetry.execute(trading_path_count(), %{counter_measurement() => count})
  end

  @spec report_price_update() :: :ok
  def report_price_update do
    :telemetry.execute(price_update(), %{counter_measurement() => 1})
  end

  @spec report_trade_executed() :: :ok
  def report_trade_executed do
    :telemetry.execute(trade_executed(), %{counter_measurement() => 1})
  end

  @spec report_trade_failed() :: :ok
  def report_trade_failed do
    :telemetry.execute(trade_failed(), %{counter_measurement() => 1})
  end
end
