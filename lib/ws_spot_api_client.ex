defmodule WSSpotApiClient do
  use GenServer

  def start_link(api_key, api_secret) do
    GenServer.start_link(__MODULE__, {api_key, api_secret}, name: __MODULE__)
  end

  def init({api_key, api_secret}) do
    {:ok, conn} =
      WebSockex.start_link("wss://stream.binance.com:9443/ws", __MODULE__, %{
        api_key: api_key,
        api_secret: api_secret
      })

    {:ok, conn}
  end

  def make_order(symbol, quantity) do
    GenServer.call(__MODULE__, {:make_order, symbol, quantity})
  end

  def get_balances(asset) do
    GenServer.call(__MODULE__, {:get_balances, asset})
  end

  def handle_call({:make_order, symbol, quantity}, _from, state) do
    _order_request = WSSpotApi.new_order_request(symbol, quantity)
    # Send the order request
    {:reply, :ok, state}
  end

  def handle_call({:get_balances, asset}, _from, state) do
    _balance_request = WSSpotApi.get_balance_request(asset)
    # Send the get balance request
    {:reply, :ok, state}
  end

  def handle_info({:ping, _}, state) do
    {:reply, :pong, state}
  end
end
