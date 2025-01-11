defmodule Balance do
  @moduledoc """
  This process is responsible for tracking the balance of all assets
  """

  alias Balance.Impl

  use Agent

  @doc """
  Starts the balance process
  """

  @spec start_link(balance_map :: %{String.t() => float()}) :: {:ok, pid}
  def start_link(balance_map) do
    Agent.start_link(fn -> Impl.new(balance_map) end, name: __MODULE__)
  end

  @doc """
  Gets the balance of an asset
  """
  @spec get_balance(asset :: String.t()) :: float()
  def get_balance(asset) do
    Agent.get(__MODULE__, fn state -> Impl.get_balance(state, asset) end)
  end

  @doc """
  Updates the balance of an asset
  """
  @spec update_balance(asset :: String.t(), amount :: float()) :: :ok
  def update_balance(asset, amount) do
    Agent.update(__MODULE__, fn state -> Impl.update_balance(state, asset, amount) end)
  end
end
