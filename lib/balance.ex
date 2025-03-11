defmodule Balance do
  @moduledoc """
  This process is responsible for tracking the balance of all assets
  """

  alias Balance.Impl

  use Agent

  @doc """
  Starts the balance process
  """
  @spec start_link(args :: any()) :: {:ok, pid}
  def start_link(_args) do
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
  Gets all balances over 0
  """
  @spec get_balances() :: map()
  def get_balances do
    Agent.get(__MODULE__, fn state -> Impl.get_balances(state) end)
  end

  @doc """
  Decrement the balance of an asset
  """
  @spec reserve!(asset :: String.t(), amount :: Decimal.t()) :: :ok
  def reserve!(asset, amount) do
    Agent.update(__MODULE__, fn state ->
      Impl.decrement!(state, asset, amount)
    end)
  end

  @doc """
  Increment the balance of multiple assets
  """
  @spec release(asset_map :: map()) :: :ok
  def release(asset_map) do
    Agent.update(__MODULE__, fn state -> Impl.increment_map(state, asset_map) end)
  end
end
