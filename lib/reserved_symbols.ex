defmodule ReservedSymbols do
  @moduledoc """
  Module for reserving symbols for trading
  """

  require Logger
  alias ReservedSymbols.Impl
  alias Types.TradingSymbol

  use Agent

  @doc """
  Starts the reserved symbols process
  """
  @spec start_link(args :: any()) :: {:ok, pid()}
  def start_link(_args) do
    Logger.info("Starting reserved symbols")

    Agent.start_link(
      fn ->
        # trap exits to allow for finishing trades on exit
        Process.flag(:trap_exit, true)
        Impl.new()
      end,
      name: __MODULE__
    )
  end

  @doc """
  Get map of reserved symbols
  """
  @spec get_reserved() :: list({String.t(), :long | :short})
  def get_reserved do
    Agent.get(__MODULE__, fn state -> Impl.get_reserved(state) end)
  end

  @doc """
  Reserves all symbols in a list

  Reservation is based on symbol and position, thus it is possible to reserve the same symbol 2 times (long and short)

  raises Error if any symbol is already reserved
  """
  @spec reserve_list!(symbols :: list(TradingSymbol.t())) :: :ok
  def reserve_list!(symbols) do
    Agent.update(__MODULE__, fn state -> Impl.reserve_list!(state, symbols) end)
  end

  @doc """
  Releases all symbols in a list

  raises Error if any symbol is not reserved
  """
  @spec release_list!(symbols :: list(TradingSymbol.t())) :: :ok
  def release_list!(symbols) do
    Agent.update(__MODULE__, fn state -> Impl.release_list!(state, symbols) end)
  end
end
