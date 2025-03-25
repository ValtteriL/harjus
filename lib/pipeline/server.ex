defmodule Pipeline.Server do
  @moduledoc """
  Server for the trade client
  """

  use GenServer

  alias Pipeline.Impl

  @impl GenServer
  def init(_args) do
    {:ok, Impl.new()}
  end

  @impl GenServer
  def handle_cast({:handle_opportunities, opportunities}, state) do
    {:noreply, Impl.handle_opportunities(state, opportunities)}
  end
end
