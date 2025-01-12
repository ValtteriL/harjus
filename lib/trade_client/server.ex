defmodule TradeClient.Server do
  @moduledoc """
  Server for the trade client
  """

  use GenServer

  alias TradeClient.Impl

  @impl true
  def init(args) do
    {:ok, args}
  end

  @impl true
  def handle_cast({:market_order, {trading_symbol, quantity}}, state) do
    {:noreply, Impl.market_order(state, trading_symbol, quantity)}
  end

  # handle messages from FIX server
  @impl true
  def handle_info({:ssl, _socket, data}, state) do
    {:noreply, Impl.handle_fix_message(state, data)}
  end

  def handle_info({:ssl_closed, _}, state), do: {:stop, :connection_closed, state}
  def handle_info({:ssl_error, _}, state), do: {:stop, :connection_error, state}
end
