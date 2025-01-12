defmodule TradeClient.Impl do
  @moduledoc """
  Implementation of the trade client

  Manages FIX session state, makes Trade requests, relays executionreports to executor

  https://github.com/binance/binance-spot-api-docs/blob/master/fix-api.md
  """

  require Logger
  alias TradeClient.BinanceFixApi

  @type state() :: %{
          socket: any(),
          seq_num: integer(),
          sender_comp_id: String.t()
        }

  def new do
    is_prod = Application.fetch_env!(:harjus, :is_prod)
    api_key = Application.fetch_env!(:harjus, :binance_ed25519_api_key)
    private_key = Application.fetch_env!(:harjus, :binance_ed25519_private_key)

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

    {:ok, %{socket: socket, seq_num: seq_num + 1, sender_comp_id: sender_comp_id}}
  end

  @spec market_order(state :: state(), trading_symbol :: TradingSymbol.t(), quantity :: float()) ::
          state()
  def market_order(state, trading_symbol, quantity) do
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

    %{state | seq_num: state.seq_num + 1}
  end

  def handle_fix_message(state, data) do
    case BinanceFixApi.parse_message(data) do
      {:heartbeat} ->
        # ignore

        Logger.debug("FIX heartbeat")
        state

      {:test_request, test_request_id} ->
        # Respond with heartbeat

        Logger.debug("FIX test request: #{test_request_id}")

        :ok =
          :ssl.send(
            state.socket,
            BinanceFixApi.heartbeat(state.seq_num, state.sender_comp_id, test_request_id)
          )

        %{state | seq_num: state.seq_num + 1}

      {:reject, reason} ->
        # this is fatal - bug in request
        raise "FIX request rejected: #{reason}"

      {:logon} ->
        # ignore
        Logger.info("FIX logon successful")
        state

      {:news} ->
        # this is fatal - must reconnect
        raise "FIX connection will be reset"

      {:execution_report, execution_report} ->
        # relay to executor
        Executor.send_execution_report(execution_report)
        state

      {:unknown, message} ->
        Logger.error("Unknown message")
        Logger.debug(inspect(message))
        state
    end
  end
end
