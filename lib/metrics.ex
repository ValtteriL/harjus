defmodule Metrics do
  @moduledoc "Module for instrumenting telemetry events"

  alias Metrics.Impl

  @spec metrics() :: [
          Telemetry.Metrics.Counter.t()
          | Telemetry.Metrics.Summary.t()
          | Telemetry.Metrics.LastValue.t()
        ]
  defdelegate metrics(), to: Impl

  @spec report_trading_symbol_count(count :: integer()) :: :ok
  defdelegate report_trading_symbol_count(count), to: Impl

  @spec report_trading_path_count(count :: integer()) :: :ok
  defdelegate report_trading_path_count(count), to: Impl

  @spec report_price_update() :: :ok
  defdelegate report_price_update(), to: Impl

  @spec report_trade_executed() :: :ok
  defdelegate report_trade_executed(), to: Impl

  @spec report_trade_failed() :: :ok
  defdelegate report_trade_failed(), to: Impl

  @spec report_trade_attempted() :: :ok
  defdelegate report_trade_attempted(), to: Impl

  @spec report_trade_losing() :: :ok
  defdelegate report_trade_losing(), to: Impl

  @spec report_trade_winning() :: :ok
  defdelegate report_trade_winning(), to: Impl

  @spec report_trade_report_delta(delta :: %{String.t() => Decimal.t()}) :: :ok
  defdelegate report_trade_report_delta(delta), to: Impl
end
