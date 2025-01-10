defmodule Executor do
  @moduledoc """
  Process for executing trades.

  Gets approved and prioritized opportunities from PortfolioManager,
  and executes them.

  While executing a trade, discards all new opportunities.
  """

  @type opportunity() :: {path :: [TradingSymbol.t()], profit :: float(), capacity :: float()}

  alias Executor.Impl

  @doc """
  Start the executor

  """
  @spec start_link(arg :: any()) :: {:ok, pid()}
  def start_link(arg) do
    GenServer.start_link(Executor.Server, Impl.new(arg), name: __MODULE__)
  end

  @doc """
  Send opportunity to Executor
  """
  @spec execute_opportunity(opportunity :: opportunity()) :: :ok
  def execute_opportunity(opportunity) do
    GenServer.cast(__MODULE__, {:execute_opportunity, opportunity})
  end

  @doc """
  Send execution report to Executor
  """
  def send_execution_report(execution_report) do
    GenServer.cast(__MODULE__, {:send_execution_report, execution_report})
  end
end
