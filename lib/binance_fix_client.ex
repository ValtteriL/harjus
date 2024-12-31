defmodule BinanceFixClient do
  @moduledoc """
  Binance FIX client

  Manages FIX session state, makes Trade requests, relays executionreports to executor

  https://github.com/binance/binance-spot-api-docs/blob/master/fix-api.md
  """

  use GenServer
  require Logger

  @type args() :: %{
          is_prod: bool(),
          public_key: String.t(),
          private_key: String.t()
        }
  @type state() :: %{
          # executor pid
          pid: pid(),
          socket: any()
        }
  @type trading_symbol() :: {charlist(), :long | :short}

  @spec start_link(is_prod :: bool()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(is_prod) do
    GenServer.start_link(__MODULE__, is_prod, name: __MODULE__)
  end

  @impl true
  @spec init(args()) :: {:ok, state()}
  def init(%{is_prod: is_prod, public_key: public_key, private_key: private_key}) do
    pid = Process.whereis(Executor)

    url =
      if is_prod do
        "tcp+tls://fix-oe.binance.com:9000"
      else
        "tcp+tls://fix-oe.testnet.binance.vision:9000"
      end

    # start FIX session
    {:ok, socket} = :gen_tcp.connect(url, [active: false], 5_000)

    # start TLS session
    {:ok, tls_socket} =
      :ssl.connect(
        socket,
        [{:verify, :verify_peer}, {:cacerts, :public_key.cacerts_get()}],
        5_000
      )

    # set socket to active binary mode
    :ssl.setopts(tls_socket, [{:active, true}, :binary])

    # logon
    :ok =
      :gen_tcp.send(tls_socket, BinanceFixApi.logon(public_key, private_key))

    {:ok, %{pid: pid, socket: tls_socket}}
  end

  # API

  @spec market_order(
          pid :: pid(),
          trading_symbol :: trading_symbol(),
          quantity :: float()
        ) :: :ok
  def market_order(pid, trading_symbol, quantity) do
    Logger.debug("Market order: #{trading_symbol} #{quantity}")
    GenServer.cast(pid, {:market_order, {trading_symbol, quantity}})
  end

  # Callbacks

  # send market order
  @impl true
  def handle_cast({:market_order, {trading_symbol, quantity}}, state) do
    :ok =
      :gen_tcp.send(state.socket, BinanceFixApi.market_order_request(trading_symbol, quantity))

    {:noreply, state}
  end

  # handle messages from FIX server
  @impl true
  def handle_info({:tcp, _socket, data}, state) do
    case BinanceFixApi.parse_message(data) do
      {:heartbeat} ->
        # ignore
        :ok

      {:test_request} ->
        # Respond with heartbeat
        :ok =
          :gen_tcp.send(
            state.socket,
            BinanceFixApi.heartbeat()
          )

        :ok

      {:reject} ->
        # this is fatal - bug in request
        raise "FIX request rejected"
        :ok

      {:logon} ->
        # ignore
        :ok

      {:news} ->
        # this is fatal - must reconnect
        raise "FIX connection will be reset"
        :ok

      {:execution_report, execution_report} ->
        # relay to executor
        Executor.send_execution_report(state.pid, execution_report)
        :ok

      {:unknown, message} ->
        Logger.error("Unknown message")
        Logger.debug(inspect(message))
    end

    {:noreply, state}
  end

  def handle_info({:tcp_closed, _}, state), do: {:stop, :connection_closed, state}
  def handle_info({:tcp_error, _}, state), do: {:stop, :connection_error, state}
end
