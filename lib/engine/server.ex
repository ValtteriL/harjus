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

  # handle responses from port
  # handle only complete messages (eol) https://www.erlang.org/doc/apps/erts/erlang.html#open_port/2
  @impl GenServer
  def handle_info({_port, {:data, {:eol, msg}}}, state) do
    {:noreply, Impl.relay_opportunities(state, msg)}
  end
end
