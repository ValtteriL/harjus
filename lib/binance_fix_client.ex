defmodule BinanceFixClient do
  @moduledoc """
  Binance FIX client

  Manages FIX session state, makes Trade requests, relays executionreports to executor

  https://github.com/binance/binance-spot-api-docs/blob/master/fix-api.md
  """

  use GenServer
  require Logger

  defmodule Args do
    @moduledoc """
    Binance FIX client arguments
    """
    @enforce_keys [:is_prod, :api_key, :private_key]
    defstruct [:api_key, :private_key, is_prod: false]

    @type t :: %__MODULE__{
            is_prod: bool(),
            api_key: String.t(),
            private_key: String.t()
          }
  end

  @type state() :: %{
          # executor pid
          pid: pid(),
          socket: any(),
          seq_num: integer(),
          sender_comp_id: String.t()
        }
  @type trading_symbol() :: {charlist(), :long | :short}

  @spec start_link(args :: Args.t()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  @spec init(Args.t()) :: {:ok, state()}
  def init(%Args{is_prod: is_prod, api_key: api_key, private_key: private_key}) do
    pid = Process.whereis(Executor)

    {addr, port} =
      if is_prod do
        {~c"fix-oe.binance.com", 9000}
      else
        {~c"fix-oe.testnet.binance.vision", 9000}
      end

    # start FIX session
    opts = [
      :binary,
      {:active, true},
      {:verify, :verify_none},
      {:cacerts, :public_key.cacerts_get()}
    ]

    {:ok, socket} = :ssl.connect(addr, port, opts)

    seq_num = 1

    # generate random sender comp id
    sender_comp_id = :crypto.strong_rand_bytes(4) |> Base.encode16() |> String.downcase()

    # logon
    :ok =
      :ssl.send(socket, BinanceFixApi.logon(seq_num, sender_comp_id, api_key, private_key))

    {:ok, %{pid: pid, socket: socket, seq_num: seq_num + 1, sender_comp_id: sender_comp_id}}
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
      :ssl.send(
        state.socket,
        BinanceFixApi.market_order_request(
          state.seq_num,
          state.sender_comp_id,
          trading_symbol,
          quantity
        )
      )

    {:noreply, %{state | seq_num: state.seq_num + 1}}
  end

  # handle messages from FIX server
  @impl true
  def handle_info({:ssl, _socket, data}, state) do
    case BinanceFixApi.parse_message(data) do
      {:heartbeat} ->
        # ignore

        Logger.debug("FIX heartbeat")
        {:noreply, state}

      {:test_request, test_request_id} ->
        # Respond with heartbeat

        Logger.debug("FIX test request: #{test_request_id}")

        :ok =
          :ssl.send(
            state.socket,
            BinanceFixApi.heartbeat(state.seq_num, state.sender_comp_id, test_request_id)
          )

        {:noreply, %{state | seq_num: state.seq_num + 1}}

      {:reject, reason} ->
        # this is fatal - bug in request
        raise "FIX request rejected: #{reason}"
        :ok

      {:logon} ->
        # ignore
        Logger.info("FIX logon successful")
        {:noreply, state}

      {:news} ->
        # this is fatal - must reconnect
        raise "FIX connection will be reset"

      {:execution_report, execution_report} ->
        # relay to executor
        Executor.send_execution_report(state.pid, execution_report)
        {:noreply, state}

      {:unknown, message} ->
        Logger.error("Unknown message")
        Logger.debug(inspect(message))
        {:noreply, state}
    end
  end

  def handle_info({:ssl_closed, _}, state), do: {:stop, :connection_closed, state}
  def handle_info({:ssl_error, _}, state), do: {:stop, :connection_error, state}
end
