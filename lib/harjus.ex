defmodule Harjus do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  require Logger

  use Application

  @impl true
  def start(_type, _args) do
    # discover trading paths
    Logger.info("Starting Harjus")
    Logger.info("Running in production: #{Application.fetch_env!(:harjus, :is_prod)}")
    Logger.info("Start symbols: #{inspect(Application.fetch_env!(:harjus, :start_symbols))}")

    Logger.info("Requesting symbols")

    symbols =
      Binance.get_symbols(Application.fetch_env!(:harjus, :is_prod))

    Logger.info("Requesting prices")

    prices =
      Binance.get_symbol_prices()

    Logger.info("Generating trading paths")

    {trading_paths, symbol_list} =
      Arbmapper.generate_trading_paths(
        symbols,
        starting_symbols: Application.fetch_env!(:harjus, :start_symbols),
        depth: Application.fetch_env!(:harjus, :max_trading_path_length)
      )

    Logger.debug(
      "Max trading path length: #{inspect(Application.fetch_env!(:harjus, :max_trading_path_length))}"
    )

    Logger.debug("Number of trading paths: #{length(trading_paths)}")
    Logger.debug("Number of symbols: #{length(symbol_list)}")

    Logger.info("Requesting balances")

    balances =
      Binance.get_balances(
        Application.fetch_env!(:harjus, :is_prod),
        Application.fetch_env!(:harjus, :binance_ed25519_api_key),
        Application.fetch_env!(:harjus, :binance_ed25519_private_key)
      )

    # multiple book streamers with 200 symbols each
    book_streamers =
      symbol_list
      |> Enum.chunk_every(200)
      |> Enum.map_reduce(1, fn partial_list, acc ->
        {Supervisor.child_spec(
           {BookStreamer, {partial_list, Application.fetch_env!(:harjus, :is_prod)}},
           id: String.to_atom("book_streamer_#{acc}")
         ), acc + 1}
      end)
      |> elem(0)

    Logger.debug("Book streamers: #{inspect(book_streamers)}")
    Logger.debug("Number of book streamers: #{length(book_streamers)}")

    pm_args = %{
      min_profit_percentage: Application.fetch_env!(:harjus, :min_profit_percentage),
      min_capacity: Application.fetch_env!(:harjus, :min_capacity),
      commission: Application.fetch_env!(:harjus, :commission),
      relative_asset_values: AssetComparer.calculate_relative_values(symbols, prices, "BTC")
    }

    children =
      [
        # Starts a worker by calling: HelloWorld.Worker.start_link(arg)
        # {HelloWorld.Worker, arg}

        # processes are started in order
        {Balance, balances},
        {Executor, []},
        {PortfolioManager, pm_args},
        {OpportunityWatcher, trading_paths},
        {BinanceFixClient,
         %BinanceFixClient.Args{
           api_key: Application.fetch_env!(:harjus, :binance_ed25519_api_key),
           private_key: Application.fetch_env!(:harjus, :binance_ed25519_private_key),
           is_prod: Application.fetch_env!(:harjus, :is_prod)
         }}
      ] ++ book_streamers

    Logger.debug("Children: #{inspect(children)}")
    Logger.debug("Number of children: #{length(children)}")

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :rest_for_one, name: Harjus]

    Logger.info("Starting child processes")
    Supervisor.start_link(children, opts)
  end
end
