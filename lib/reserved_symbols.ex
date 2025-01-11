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
  Checks if symbol is reserved
  """
  @spec reserved?(symbol :: String.t()) :: boolean()
  def reserved?(symbol) do
    Agent.get(__MODULE__, fn state -> Impl.reserved?(state, symbol) end)
  end

  @doc """
  Reserves a symbol
  """
  @spec reserve(symbol :: String.t()) :: :ok
  def reserve(symbol) do
    Agent.update(__MODULE__, fn state -> Impl.reserve(state, symbol) end)
  end

  @doc """
  Releses a symbol
  """
  @spec release(symbol :: String.t()) :: :ok
  def release(symbol) do
    Agent.update(__MODULE__, fn state -> Impl.release(state, symbol) end)
  end
end
