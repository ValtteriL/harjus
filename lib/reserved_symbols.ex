defmodule ReservedSymbols do
  @moduledoc """
  Module for reserving symbols for trading
  """

  alias ReservedSymbols.Impl

  use Agent

  @doc """
  Starts the balance process
  """

  def start_link do
    start_link([])
  end

  @spec start_link(args :: any()) :: {:ok, pid}
  def start_link(_args) do
    Agent.start_link(fn -> Impl.new() end, name: __MODULE__)
  end

  @doc """
  Gets all balances over 0
  """
  @spec get_balances() :: map()
  def get_balances do
    Agent.get(__MODULE__, fn state -> Impl.get_balances(state) end)
  end
end
