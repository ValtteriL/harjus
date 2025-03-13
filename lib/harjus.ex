defmodule Harjus do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  require Logger

  use Application

  @impl Application
  def start(_type, _args) do
    IO.puts(banner())

    Logger.info("Starting Harjus")

    # discover trading paths
    market_data = MarketData.new()

    {trading_paths, symbol_list} =
      MarketData.trading_paths(
        market_data,
        Application.fetch_env!(:harjus, :start_symbols),
        Application.fetch_env!(:harjus, :max_trading_path_length),
        Application.fetch_env!(:harjus, :blacklisted_start_symbols)
      )

    Logger.info("Trading symbols: #{length(symbol_list)}")
    Logger.info("Trading paths: #{length(trading_paths)}")

    Metrics.report_trading_symbol_count(length(symbol_list))
    Metrics.report_trading_path_count(length(trading_paths))

    children =
      [
        # Starts a worker by calling: HelloWorld.Worker.start_link(arg)
        # {HelloWorld.Worker, arg}

        # processes are started in order

        # erlang VM telemetry poller
        {:telemetry_poller, measurements: [], period: :timer.seconds(10)},

        # telemetry reporter
        cond do
          # silence metrics
          Application.fetch_env!(:harjus, :console_silence) ->
            {Agent, fn -> :ok end}

          # metrics to console
          Application.fetch_env!(:harjus, :console_telemetry) ->
            {Telemetry.Metrics.ConsoleReporter, [metrics: Metrics.metrics()]}

          # metrics to cloudwatch
          true ->
            {TelemetryMetricsCloudwatch,
             [metrics: Metrics.metrics(), namespace: "Harjus", push_interval: 300_000]}
        end,

        # streamer (slowest to start, thus restart the least)
        {PriceStreamer, symbol_list},

        # supervisor for looking after trade execution tasks
        # if this crashes, balance and reservedsymbols may be incorrect, thus must be restarted too
        {Task.Supervisor, name: TraderSupervisor, auto_shutdown: :any_significant},

        # utilities
        {Balance, []},
        {ReservedSymbols, []},

        # trade client
        {TradeClient, []},

        # the pipeline
        {Pipeline,
         [
           trading_paths,
           Application.fetch_env!(:harjus, :commission),
           MarketData.relative_values(market_data, "BTC")
         ]}
      ]

    # if a child process terminates, the terminated child process
    # and the rest of the children started after it, are terminated and restarted.
    opts = [strategy: :rest_for_one, name: Harjus]

    Supervisor.start_link(children, opts)
  end

  defp banner do
    """

                      :=======:.
                    :============.
                  .-==+++=++======-
              .:==========++*+++==+=.
           :==-=--=---===+=====++=:
        :=**=::--=====Harjus======+=:.
      :++++=:-:=-=-==-==============+++=:
     ==+=::-:-=-=========+=====+===++===+*=:
    :=++=:::==:-=====-::::::-========+*+++++=.
    :++--:-:-:::::::..    .=+==+=::--==++++++=.
     ..                     :.  .    :=*+-+++***=:
                                       :+:.=**+*=:
                                           :***.
                                            =++:
                                            .*+:
                                             =+:
                                             :=

    """
  end
end
