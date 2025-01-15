defmodule Trader do
  @moduledoc """
  Process for executing trades.

  Gets approved and prioritized opportunities from PortfolioManager,
  and executes them.

  While executing a trade, discards all new opportunities.
  """

  alias Trader.Impl
  alias Types.TradingSymbol
  @type opportunity() :: {path :: [TradingSymbol.t()], profit :: float(), capacity :: float()}

  @doc """
  Start the trader

  """
  @spec start_link(arg :: any()) :: {:ok, pid()}
  def start_link(arg) do
    GenServer.start_link(Trader.Server, Impl.new(arg), name: __MODULE__)
  end

  @doc """
  Send opportunity to trader
  """
  @spec execute_opportunity(opportunity :: opportunity()) :: :ok
  def execute_opportunity(opportunity) do
    GenServer.cast(__MODULE__, {:execute_opportunity, opportunity})
  end
end
