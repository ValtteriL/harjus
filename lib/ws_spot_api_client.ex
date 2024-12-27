defmodule WSSpotApiClient do
  use GenServer
  require Logger

  def start_link(api_key, api_secret) do
    GenServer.start_link(__MODULE__, {api_key, api_secret}, name: __MODULE__)
  end

  def init({api_key, api_secret}) do
    {:ok, %{api_key: api_key, api_secret: api_secret}, {:continue, :connect}}
  end

  def handle_continue(:connect, state) do
    case connect(state.api_key, state.api_secret) do
      {:ok, conn} ->
        {:noreply, Map.put(state, :conn, conn)}

      {:error, reason} ->
        Logger.error("Failed to connect: #{reason}")
        {:stop, reason, state}
    end
  end

  def make_order(order) do
    GenServer.call(__MODULE__, {:make_order, order})
  end

  def get_balances() do
    GenServer.call(__MODULE__, :get_balances)
  end

  def handle_call({:make_order, order}, _from, state) do
    case send_order(state.conn, order) do
      {:ok, response} ->
        {:reply, {:ok, response}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call(:get_balances, _from, state) do
    case fetch_balances(state.conn) do
      {:ok, balances} ->
        {:reply, {:ok, balances}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_info({:ping, _}, state) do
    {:noreply, state}
  end

  defp connect(api_key, api_secret) do
    # Implement the connection logic here
    {:ok, :connection}
  end

  defp send_order(conn, order) do
    # Implement the order sending logic here
    {:ok, :order_response}
  end

  defp fetch_balances(conn) do
    # Implement the balance fetching logic here
    {:ok, :balances}
  end
end
