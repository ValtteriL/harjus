defmodule Executor do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{state: :checking_balance, balance: nil, opportunities: []}}
  end

  def handle_cast({:opportunity, opportunity}, %{state: :waiting_for_opportunities} = state) do
    {:noreply, %{state | opportunities: [opportunity | state.opportunities]}}
  end

  def handle_cast({:opportunity, _opportunity}, state) do
    {:noreply, state}
  end

  def handle_cast({:trade_update, trade_update}, %{state: :waiting_for_fill} = state) do
    # Handle trade filled update
    {:noreply, state}
  end

  def handle_cast({:trade_update, _trade_update}, state) do
    {:noreply, state}
  end

  def send_opportunity(pid, opportunity) do
    GenServer.cast(pid, {:opportunity, opportunity})
  end

  def send_trade_update(pid, trade_update) do
    GenServer.cast(pid, {:trade_update, trade_update})
  end
end
