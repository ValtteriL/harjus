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
        Application.fetch_env!(:harjus, :max_trading_path_length)
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

        # utilities
        {Balance, []},
        {ReservedSymbols, []},

        # supervisor for looking after trade execution tasks
        {Task.Supervisor, name: TraderSupervisor, restart: :transient, max_restarts: 0},

        # trade client
        {TradeClient, []},

        # streamer + pipeline
        {PriceStreamer, symbol_list},
        {Pipeline,
         [
           trading_paths,
           Application.fetch_env!(:harjus, :commission),
           MarketData.relative_values(market_data, "BTC")
         ]}
      ]

    # If a child process terminates, all other child processes are terminated
    # and then all child processes (including the terminated one) are restarted
    opts = [strategy: :one_for_all, name: Harjus]

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
