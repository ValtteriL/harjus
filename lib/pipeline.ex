defmodule Pipeline do
  @moduledoc """
  Pipeline for processing price updates and dispatching traders
  """

  alias Pipeline.Server
  alias Types.PriceUpdate

  @doc """
  Create new pipeline
  """
  @spec start_link(args :: tuple()) :: {:ok, pid()}
  def start_link(args = {_trading_paths, _commission, _relative_asset_values}) do
    GenServer.start_link(Server, args, name: __MODULE__)
  end

  def child_spec(args = {_trading_paths, _commission, _relative_asset_values}) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [args]}
    }
  end

  @spec price_update(update :: PriceUpdate.t()) :: :ok
  def price_update(update) do
    GenServer.cast(__MODULE__, {:price_update, update})
  end
end
