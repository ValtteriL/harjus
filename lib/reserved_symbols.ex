defmodule ReservedSymbols do
  @moduledoc """
  This process is responsible for tracking symbols that are currently being traded
  """

  use Agent

  @doc """
  Starts the reserved symbols process
  """

  @spec start_link() :: {:ok, pid}
  def start_link do
    Agent.start_link(fn -> MapSet.new() end, name: __MODULE__)
  end

  @doc """
  Checks if symbol is reserved
  """
  @spec reserved?(symbol :: String.t()) :: boolean()
  def reserved?(symbol) do
    Agent.get(__MODULE__, fn state -> MapSet.member?(state, symbol) end)
  end

  @doc """
  Reserves a symbol
  """
  @spec reserve(symbol :: String.t()) :: :ok
  def reserve(symbol) do
    Agent.update(__MODULE__, fn state -> MapSet.put(state, symbol) end)
  end

  @doc """
  Releses a symbol
  """
  @spec release(symbol :: String.t()) :: :ok
  def release(symbol) do
    Agent.update(__MODULE__, fn state -> MapSet.delete(state, symbol) end)
  end
end
