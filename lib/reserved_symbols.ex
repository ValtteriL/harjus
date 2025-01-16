defmodule ReservedSymbols do
  @moduledoc """
  This process is responsible for tracking symbols that are currently being traded
  """

  use Agent
  alias ReservedSymbols.Impl

  @doc """
  Starts the reserved symbols process
  """

  @spec start_link() :: {:ok, pid}
  def start_link do
    Agent.start_link(fn -> Impl.new() end, name: __MODULE__)
  end

  @doc """
  Checks if any symbol in list is reserved
  """
  @spec reserved?(symbols :: [String.t()]) :: boolean()
  def reserved?(symbols) do
    Agent.get(__MODULE__, fn state -> Impl.reserved?(state, symbols) end)
  end

  @doc """
  Reserves a list of symbols
  """
  @spec reserve(symbols :: [String.t()]) :: :ok | :error
  def reserve(symbols) do
    Agent.get_and_update(__MODULE__, fn state -> Impl.reserve(state, symbols) end)
  end

  @doc """
  Releses a list of symbols
  """
  @spec release(symbols :: [String.t()]) :: :ok
  def release(symbols) do
    Agent.update(__MODULE__, fn state -> Impl.release(state, symbols) end)
  end
end
