defmodule Balance do
  @moduledoc """
  This process is responsible for tracking the balance of all assets
  """

  alias Balance.Impl

  use Agent

  @doc """
  Starts the balance process
  """

  @spec start_link(balance_map :: %{String.t() => Decimal.t()}) :: {:ok, pid}
  def start_link(balance_map) do
    Agent.start_link(fn -> Impl.new(balance_map) end, name: __MODULE__)
  end

  @doc """
  Gets the balance of an asset
  """
  @spec get(asset :: String.t()) :: Decimal.t()
  def get(asset) do
    Agent.get(__MODULE__, fn state -> Impl.get(state, asset) end)
  end

  @doc """
  Updates the balance of an asset
  """
  @spec update(asset :: String.t(), amount :: Decimal.t()) :: :ok
  def update(asset, amount) do
    Agent.update(__MODULE__, fn state -> Impl.update(state, asset, amount) end)
  end

  @doc """
  Reserves the balance of an asset upto a certain amount
  """
  @spec reserve_upto(asset :: String.t(), amount :: Decimal.t()) :: Decimal.t()
  def reserve_upto(asset, amount) do
    Agent.get_and_update(__MODULE__, fn state -> Impl.reserve_upto(state, asset, amount) end)
  end
end
