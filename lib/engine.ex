defmodule Engine do
  @moduledoc """
  This process is responsible for relaying messages to port and relaying
  responses to the pipeline
  """

  # alias Engine.Impl
  alias Engine.Server

  require Logger

  @doc """
  Starts the balance process
  """
  @spec start_link(args :: any()) :: {:ok, pid}
  def start_link(args) do
    Logger.info("Starting engine")

    GenServer.start_link(
      Server,
      args,
      name: __MODULE__
    )
  end

  @doc """
  Price update
  """
  @spec price_update(update :: String.t()) :: :ok
  def price_update(update) do
    GenServer.cast(__MODULE__, {:price_update, update})
  end
end
