defmodule TradeClient.Server do
  @moduledoc """
  Server for the trade client
  """

  use GenServer

  alias TradeClient.Impl

  @impl GenServer
  def init(args) do
    {:ok, args}
  end

  @impl GenServer
  def handle_call({:market_order, {trading_symbol, quantity}}, from, state) do
    {:noreply, Impl.market_order(state, from, trading_symbol, quantity)}
  end

  # handle messages from FIX server
  @impl GenServer
  def handle_info({:ssl, _socket, data}, state) do
    {:noreply, Impl.handle_fix_message(state, data)}
  end

  def handle_info({:ssl_closed, _}, state), do: {:stop, :connection_closed, state}
  def handle_info({:ssl_error, _}, state), do: {:stop, :connection_error, state}
end
