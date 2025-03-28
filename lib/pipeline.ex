defmodule Pipeline do
  @moduledoc """
  Pipeline for processing price updates and dispatching traders
  """

  alias Pipeline.Server
  alias Types.PlannedExecution

  require Decimal
  require Logger

  @doc """
  Create new pipeline
  """
  @spec start_link() :: {:ok, pid()}
  def start_link do
    Logger.info("Starting pipeline")

    GenServer.start_link(Server, [], name: __MODULE__)
  end

  def child_spec(_args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
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
