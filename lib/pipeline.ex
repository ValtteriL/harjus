defmodule Pipeline do
  @moduledoc """
  Pipeline for processing price updates and dispatching traders
  """

  alias Pipeline.Server
  alias Types.PlannedExecution
  alias Types.TradingSymbol

  require Decimal
  require Logger

  @doc """
  Create new pipeline
  """
  @spec start_link(
          trading_paths :: list(list(TradingSymbol.t())),
          commission :: Decimal.t(),
          relative_asset_values :: map()
        ) :: {:ok, pid()}
  def start_link(trading_paths, commission, relative_asset_values) do
    Logger.info("Starting pipeline")

    GenServer.start_link(Server, {trading_paths, commission, relative_asset_values},
      name: __MODULE__
    )
  end

  def child_spec(args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, args}
    }
  end

  @doc """
  Handle opportunities
  """
  @spec handle_opportunities(opportunities :: list(PlannedExecution.t())) :: :ok
  def handle_opportunities(opportunities) do
    GenServer.cast(__MODULE__, {:handle_opportunities, opportunities})
  end
end
