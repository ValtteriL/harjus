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
  @spec start_link(
          trading_paths :: list(list(TradingSymbol.t())),
          commission :: Decimal.t(),
          relative_asset_values :: map()
        ) :: {:ok, pid}
  def start_link(trading_paths, commission, relative_asset_values) do
    Logger.info("Starting engine")

    GenServer.start_link(
      Server,
      {trading_paths, commission, relative_asset_values},
      name: __MODULE__
    )
  end

  def child_spec(args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, args}
    }
  end

  @doc """
  Price update
  """
  @spec price_update(update :: String.t()) :: :ok
  def price_update(update) do
    GenServer.cast(__MODULE__, {:price_update, update})
  end
end
