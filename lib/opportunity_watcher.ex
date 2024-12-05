defmodule OpportunityWatcher do
  use Agent

  @spec start([charlist()]) :: {:error, any()} | {:ok, pid()}
  @doc """
  Starts a new opportunity watcher.
  """
  def start(trading_path) do
    # TODO: init data structure for holding trading path, subscribe to trading symbol feeds
    Agent.start(fn -> trading_path end)
  end

  @doc """
  Gets a value from the `bucket` by `key`.
  """
  def get(bucket, key) do
    Agent.get(bucket, &Map.get(&1, key))
  end

  @doc """
  Puts the `value` for the given `key` in the `bucket`.
  """
  def put(bucket, key, value) do
    Agent.update(bucket, &Map.put(&1, key, value))
  end
end
