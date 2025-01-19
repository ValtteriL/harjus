defmodule Trader.TradeClient.Impl do
  @moduledoc """
  Implementation of the trade client

  Manages FIX session state, makes Trade requests, returns Trade reports

  https://github.com/binance/binance-spot-api-docs/blob/master/fix-api.md
  """

  require Logger
  alias Trader.TradeClient.BinanceFixApi
  alias Types.TradeReport
  alias Types.TradingSymbol

  defmodule State do
    @moduledoc """
    State of the trade client
    """

    @enforce_keys [:socket, :seq_num, :sender_comp_id, :outstanding_execution_reports]

    @type t :: %{
            socket: any(),
            seq_num: integer(),
            sender_comp_id: String.t(),
            outstanding_execution_reports: %{
              (client_order_id :: String.t()) => from :: any()
            }
          }

    defstruct [:socket, :seq_num, :sender_comp_id, :outstanding_execution_reports]
  end

  @order_filled BinanceFixApi.ExecutionReport.OrderStatus.filled()

  def new do
    api_key = Application.fetch_env!(:harjus, :binance_ed25519_api_key)
    private_key = Application.fetch_env!(:harjus, :binance_ed25519_private_key)
    hostname = Application.fetch_env!(:harjus, :binance_fix_api_hostname)
    port = Application.fetch_env!(:harjus, :binance_fix_api_port)

    # start FIX session
    opts = [
      :binary,
      {:active, true},
      {:verify, :verify_none},
      {:cacerts, :public_key.cacerts_get()}
    ]

    {:ok, socket} = :ssl.connect(hostname, port, opts)

    seq_num = 1

    # generate random sender comp id
    sender_comp_id = :crypto.strong_rand_bytes(4) |> Base.encode16() |> String.downcase()

    # logon
    :ok =
      :ssl.send(socket, BinanceFixApi.logon(seq_num, sender_comp_id, api_key, private_key))

    %State{
      socket: socket,
      seq_num: seq_num + 1,
      sender_comp_id: sender_comp_id,
      outstanding_execution_reports: %{}
    }
  end

  @spec market_order(
          state :: State.t(),
          from :: term(),
          trading_symbol :: TradingSymbol.t(),
          quantity :: Decimal.t()
        ) ::
          State.t()
  def market_order(state, from, trading_symbol, quantity) do
    client_order_id = :crypto.strong_rand_bytes(8) |> Base.encode16() |> String.downcase()

    :ok =
      :ssl.send(
        state.socket,
        BinanceFixApi.market_order_request(
          state.seq_num,
          state.sender_comp_id,
          trading_symbol,
          quantity,
          client_order_id
        )
      )

    # store request id with from to be able to relay execution report
    state
    |> Map.put(
      :outstanding_execution_reports,
      Map.put(state.outstanding_execution_reports, client_order_id, from)
    )
    |> Map.put(:seq_num, state.seq_num + 1)
  end

  def handle_fix_message(state, data) do
    react_to_fix_message(state, BinanceFixApi.parse_message(data))
  end

  defp react_to_fix_message(state, {:heartbeat}), do: state

  defp react_to_fix_message(state, {:test_request, test_request_id}) do
    :ok =
      :ssl.send(
        state.socket,
        BinanceFixApi.heartbeat(state.seq_num, state.sender_comp_id, test_request_id)
      )

    %{state | seq_num: state.seq_num + 1}
  end

  defp react_to_fix_message(_s, {:reject, reason}), do: raise("FIX request rejected: #{reason}")
  defp react_to_fix_message(_s, {:news}), do: raise("FIX connection will be reset")

  defp react_to_fix_message(state, {:logon}) do
    Logger.info("FIX logon successful")
    state
  end

  defp react_to_fix_message(state, {:execution_report, execution_report}) do
    # if complete, reply to trader
    Logger.info("Execution report: #{execution_report}")

    # if order is filled, relay to trader
    case execution_report.order_status do
      @order_filled ->
        from = Map.get(state.outstanding_execution_reports, execution_report.client_order_id)
        GenServer.reply(from, executionreport_to_tradereport(execution_report))

        %{
          state
          | outstanding_execution_reports:
              Map.delete(
                state.outstanding_execution_reports,
                execution_report.client_order_id
              )
        }

      _ ->
        state
    end
  end

  defp react_to_fix_message(state, {:unknown, message}) do
    Logger.error("Unknown message")
    Logger.debug(inspect(message))
    state
  end

  @buy_side BinanceFixApi.OrderSide.buy()
  @sell_side BinanceFixApi.OrderSide.sell()

  defp executionreport_to_tradereport(execution_report) do
    position =
      case execution_report.side do
        @buy_side -> :long
        @sell_side -> :short
      end

    %TradeReport{
      symbol: execution_report.symbol,
      position: position,
      quantity_base: execution_report.quantity_base,
      quantity_quote: execution_report.quantity_quote,
      quantity_fee: execution_report.fee_amount,
      fee_currency: execution_report.fee_currency
    }
  end
end
