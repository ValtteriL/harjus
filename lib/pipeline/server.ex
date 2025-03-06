defmodule Pipeline.Server do
  @moduledoc """
  Server for the trade client
  """

  use GenServer

  alias Pipeline.Impl

  @impl GenServer
  def init({trading_paths, commission, relative_asset_values}) do
    {:ok, Impl.new(trading_paths, commission, relative_asset_values)}
  end

  @impl GenServer
  def handle_cast({:price_update, update}, state) do
    {:noreply, Impl.price_update(state, update)}
  end
end
