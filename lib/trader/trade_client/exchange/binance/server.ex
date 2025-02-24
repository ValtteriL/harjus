defmodule Trader.TradeClient.Exchange.Binance.Server do
  @moduledoc """
  Server for the trade client
  """

  use GenServer

  alias Trader.TradeClient.Exchange.Binance.Impl

  @impl GenServer
  def init(_args) do
    {:ok, Impl.new()}
  end

  @impl GenServer
  def handle_call({:market_order, {trading_symbol, quantity}}, from, state) do
    {:noreply, Impl.market_order(state, from, trading_symbol, quantity)}
  end

  @impl GenServer
  def handle_call({:limit_order, {trading_symbol, quantity, price}}, from, state) do
    {:noreply, Impl.limit_order(state, from, trading_symbol, quantity, price)}
  end

  # handle messages from FIX server
  @impl GenServer
  def handle_info({:ssl, _socket, data}, state) do
    {:noreply, Impl.handle_fix_message(state, data)}
  end

  def handle_info({:ssl_closed, _}, state), do: {:stop, :connection_closed, state}
  def handle_info({:ssl_error, _}, state), do: {:stop, :connection_error, state}
end
