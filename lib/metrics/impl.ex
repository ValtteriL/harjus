defmodule Metrics.Impl do
  @moduledoc "Metrics implementation"

  import Telemetry.Metrics

  @spec metrics() :: [
          Telemetry.Metrics.Counter.t()
          | Telemetry.Metrics.Summary.t()
          | Telemetry.Metrics.LastValue.t()
        ]
  def metrics do
    [
      # market data metrics
      last_value("harjus.market_data.trading_symbol.count",
        description: "Number of trading symbols available in exchange"
      ),
      last_value("harjus.market_data.trading_path.count",
        description: "Number of possible trading paths"
      ),

      # price streamer metrics
      counter("harjus.price_streamer.price_update.count",
        description: "Number of price updates received"
      ),

      # trader metrics
      counter("harjus.trader.trade.executed.count", description: "Number of trades executed"),
      counter("harjus.trader.trade.attempted.count", description: "Number of trades attempted"),
      distribution("harjus.trader.trade.report.delta",
        tags: [:asset],
        description: "Change in asset balance after execution",
        reporter_options: [buckets: [0.05, 0.1, 0.2, 0.5, 1]]
      )
    ]
  end
end
