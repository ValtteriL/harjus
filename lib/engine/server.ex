defmodule Engine.Server do
  @moduledoc """
  Server for the engine
  """

  use GenServer

  alias Engine.Impl
  require Logger

  @impl GenServer
  def init({trading_paths, commission, relative_asset_values}) do
    {:ok, Impl.new(trading_paths, commission, relative_asset_values)}
  end

  @impl GenServer
  def handle_cast({:price_update, update}, state) do
    {:noreply, Impl.price_update(state, update)}
  end

  # print out response from port
  @impl GenServer
  def handle_info({_port, {:data, msg}}, state) do
    Logger.debug("Eixir received from port: #{msg}")
    {:noreply, state}
  end
end
