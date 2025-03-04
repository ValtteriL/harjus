defmodule MetricsTest do
  @moduledoc "Tests for Metrics"
  use ExUnit.Case
  doctest Metrics

  # suppresses log output caused by missing telemetry handler
  @moduletag :capture_log

  test "report_trading_symbol_count" do
    assert Metrics.report_trading_symbol_count(42) == :ok
  end

  test "report_trading_path_count" do
    assert Metrics.report_trading_path_count(42) == :ok
  end

  test "report_price_update" do
    assert Metrics.report_price_update() == :ok
  end

  test "report_trade_executed" do
    assert Metrics.report_trade_executed() == :ok
  end

  test "report_trade_attempted" do
    assert Metrics.report_trade_attempted() == :ok
  end

  test "report_trade_report_delta" do
    assert Metrics.report_trade_report_delta(%{"key" => Decimal.new("42.42")}) == :ok
  end

  test "metrics" do
    metrics = Metrics.metrics()
    assert length(metrics) > 0

    assert Enum.all?(metrics, fn metric ->
             case metric do
               %Telemetry.Metrics.Counter{} -> true
               %Telemetry.Metrics.Summary{} -> true
               %Telemetry.Metrics.LastValue{} -> true
               %Telemetry.Metrics.Distribution{} -> true
               _ -> false
             end
           end)
  end
end
