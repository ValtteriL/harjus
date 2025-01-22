defmodule Metrics do
  @moduledoc "Module for instrumenting telemetry events"

  alias Metrics.Impl

  @spec metrics() :: [
          Telemetry.Metrics.Counter.t()
          | Telemetry.Metrics.Summary.t()
          | Telemetry.Metrics.LastValue.t()
        ]
  defdelegate metrics(), to: Impl
end
