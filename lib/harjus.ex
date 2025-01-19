defmodule Harjus do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  require Logger

  use Application

  @impl Application
  def start(_type, _args) do
    # discover trading paths
    Logger.info("Starting Harjus")
    Logger.info("Start symbols: #{inspect(Application.fetch_env!(:harjus, :start_symbols))}")

    market_data = MarketData.new()

    {trading_paths, symbol_list} =
      MarketData.trading_paths(
        market_data,
        Application.fetch_env!(:harjus, :start_symbols),
        Application.fetch_env!(:harjus, :max_trading_path_length)
      )

    children =
      [
        # Starts a worker by calling: HelloWorld.Worker.start_link(arg)
        # {HelloWorld.Worker, arg}

        # processes are started in order

        # utilities
        {Balance, AccountData.get_balances()},
        {TradeClient, []},

        # pipeline
        {PriceStreamer, symbol_list},
        {OpportunityWatcher,
         %OpportunityWatcher.Args{
           min_profit_percentage: Application.fetch_env!(:harjus, :min_profit_percentage),
           min_capacity: Application.fetch_env!(:harjus, :min_capacity),
           commission: Application.fetch_env!(:harjus, :commission),
           trading_paths: trading_paths
         }},
        {PortfolioManager,
         %PortfolioManager.Args{
           relative_asset_values: MarketData.relative_values(market_data)
         }},
        {Trader, Application.fetch_env!(:harjus, :number_of_traders)}
      ]

    # If a child process terminates, all other child processes are terminated
    # and then all child processes (including the terminated one) are restarted
    opts = [strategy: :one_for_all, name: Harjus]

    Supervisor.start_link(children, opts)
  end
end
