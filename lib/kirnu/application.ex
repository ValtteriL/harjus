defmodule Kirnu.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # discover trading paths
    symbols = Binance.get_symbols()

    {trading_paths, symbol_list} =
      Arbmapper.generate_trading_paths(
        symbols,
        Application.fetch_env!(:kirnu, :start_symbols),
        Application.fetch_env!(:kirnu, :max_trading_path_length)
      )

    # multiple book streamers with max 1024 symbols each
    book_streamers =
      symbol_list
      |> Enum.chunk_every(1024)
      |> Enum.map(fn partial_list ->
        {BookStreamer, partial_list}
      end)

    children =
      [
        # Starts a worker by calling: HelloWorld.Worker.start_link(arg)
        # {HelloWorld.Worker, arg}

        # processes are started in order
        {PortfolioManager, []},
        {OpportunityWatcher, trading_paths}
      ] ++ book_streamers

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :rest_for_one, name: Kirnu.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
