defmodule Balance do
  @moduledoc """
  This process is responsible for tracking the balance of all assets
  """

  use Agent

  @doc """
  Starts the balance process
  """

  @spec start_link(balance_map :: %{String.t() => float()}) :: {:ok, pid}
  def start_link(balance_map) do
    Agent.start_link(fn -> balance_map end, name: __MODULE__)
  end

  @doc """
  Gets the balance of an asset
  """
  @spec get_balance(asset :: String.t()) :: float()
  def get_balance(asset) do
    Agent.get(__MODULE__, fn state -> Map.get(state, asset, 0) end)
  end

  @doc """
  Updates the balance of an asset
  """
  @spec update_balance(asset :: String.t(), amount :: float()) :: :ok
  def update_balance(asset, amount) do
    Agent.update(__MODULE__, fn state -> Map.update(state, asset, amount, &(&1 + amount)) end)
  end
end
