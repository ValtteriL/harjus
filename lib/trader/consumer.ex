defmodule Trader.Consumer do
  @moduledoc """
  ConsumerSupervisor for Trader
  """

  use ConsumerSupervisor

  alias Trader.Error.InsufficientBalanceError
  alias Trader.Error.SymbolAlreadyReservedError
  alias Trader.Impl
  alias Types.Opportunity

  @impl ConsumerSupervisor
  def init(max_number_workers) do
    children = [
      %{
        id: Trader,
        start: {__MODULE__, :handle_event, [self()]},
        restart: :temporary,
        # 5 seconds grace period
        shutdown: 5000
      }
    ]

    opts = [
      strategy: :one_for_one,
      subscribe_to: [{PortfolioManager, max_demand: max_number_workers}]
    ]

    ConsumerSupervisor.init(children, opts)
  end

  @spec handle_event(parent :: pid(), opportunity :: Opportunity.t()) :: {:ok, pid()}
  def handle_event(parent, opportunity) when is_pid(parent) do
    Task.start_link(fn ->
      # trap exits to allow some time for tasks to complete
      Process.flag(:trap_exit, true)

      try do
        Impl.execute_opportunity(opportunity)
      rescue
        # these errors are expected, ignore
        InsufficientBalanceError -> :ok
        SymbolAlreadyReservedError -> :ok
        # trigger graceful shutdown of trader on unexpected error
        _ -> Task.start(fn -> GenStage.stop(parent, :fatal_error_in_trader) end)
      end
    end)
  end
end
