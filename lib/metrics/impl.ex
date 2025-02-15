defmodule Metrics.Impl do
  @moduledoc "Metrics implementation"

  import Telemetry.Metrics

  defp trading_symbol_count, do: [:harjus, :market_data, :trading_symbol]
  defp trading_path_count, do: [:harjus, :market_data, :trading_path]
  defp price_update, do: [:harjus, :price_streamer, :price_update]
  defp trade_executed, do: [:harjus, :trader, :trade, :executed]
  defp trade_attempted, do: [:harjus, :trader, :trade, :attempted]
  defp trade_losing, do: [:harjus, :trader, :trade, :losing]
  defp trade_winning, do: [:harjus, :trader, :trade, :winning]
  defp trade_report_delta, do: [:harjus, :trader, :trade, :report]

  defp counter_measurement, do: :count
  defp summary_measurement, do: :delta

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
        trade_attempted(),
        event_name: trade_attempted(),
        measurement: counter_measurement(),
        description: "Number of trades attempted"
      ),
      counter(
        trade_losing(),
        event_name: trade_losing(),
        measurement: counter_measurement(),
        description: "Number of losing trades"
      ),
      counter(
        trade_winning(),
        event_name: trade_winning(),
        measurement: counter_measurement(),
        description: "Number of winning trades"
      ),
      summary(
        trade_report_delta(),
        event_name: trade_report_delta(),
        measurement: summary_measurement(),
        tags: [:asset],
        description: "Change in asset balance after execution"
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

  @spec report_trade_attempted() :: :ok
  def report_trade_attempted do
    :telemetry.execute(trade_attempted(), %{counter_measurement() => 1})
  end

  @spec report_trade_losing() :: :ok
  def report_trade_losing do
    :telemetry.execute(trade_losing(), %{counter_measurement() => 1})
  end

  @spec report_trade_winning() :: :ok
  def report_trade_winning do
    :telemetry.execute(trade_winning(), %{counter_measurement() => 1})
  end

  @spec report_trade_report_delta(delta :: %{String.t() => Decimal.t()}) :: :ok
  def report_trade_report_delta(delta_map) do
    delta_map
    |> Enum.each(fn {asset, delta} ->
      :telemetry.execute(
        trade_report_delta(),
        %{summary_measurement() => Decimal.to_float(delta)},
        %{
          asset: asset
        }
      )
    end)
  end
end
