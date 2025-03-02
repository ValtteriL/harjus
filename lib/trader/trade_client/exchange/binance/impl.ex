defmodule Trader.TradeClient.Exchange.Binance.Impl do
  @moduledoc """
  Implementation of the trade client

  Manages FIX session state, makes Trade requests, returns Trade reports

  https://github.com/binance/binance-spot-api-docs/blob/master/fix-api.md
  """

  require Logger
  alias Trader.TradeClient.Exchange.Binance.FixApi
  alias Trader.TradeClient.Exchange.Binance.FixApi.Const
  alias Trader.TradeClient.Exchange.Binance.FixApi.Types.ExecutionReport
  alias Trader.TradeClient.Exchange.Binance.State

  alias Types.TradeReport
  alias Types.TradingSymbol

  @order_filled ExecutionReport.OrderStatus.filled()
  @order_canceled ExecutionReport.OrderStatus.canceled()
  @order_rejected ExecutionReport.OrderStatus.rejected()
  @order_expired ExecutionReport.OrderStatus.expired()

  def new do
    api_key = Application.fetch_env!(:harjus, :binance_ed25519_api_key)
    private_key = Application.fetch_env!(:harjus, :binance_ed25519_private_key)
    hostname = String.to_charlist(Application.fetch_env!(:harjus, :binance_fix_api_hostname))
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
      :ssl.send(socket, FixApi.logon(seq_num, sender_comp_id, api_key, private_key))

    %State{
      socket: socket,
      seq_num: seq_num + 1,
      sender_comp_id: sender_comp_id,
      outstanding_execution_reports: %{}
    }
  end

  @spec limit_order(
          state :: State.t(),
          from :: term(),
          trading_symbol :: TradingSymbol.t(),
          quantity :: Decimal.t(),
          price :: Decimal.t()
        ) ::
          State.t()
  def limit_order(state, from, trading_symbol, quantity, price) do
    client_order_id = generate_client_order_id()

    :ok =
      :ssl.send(
        state.socket,
        FixApi.limit_order_request(
          state.seq_num,
          state.sender_comp_id,
          trading_symbol,
          quantity,
          price,
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
    react_to_fix_message(state, FixApi.parse_message(data))
  end

  defp react_to_fix_message(state, {:heartbeat}), do: state

  defp react_to_fix_message(state, {:test_request, test_request_id}) do
    :ok =
      :ssl.send(
        state.socket,
        FixApi.heartbeat(state.seq_num, state.sender_comp_id, test_request_id)
      )

    %{state | seq_num: state.seq_num + 1}
  end

  defp react_to_fix_message(_s, {:reject, reason}), do: raise("FIX request rejected: #{reason}")
  defp react_to_fix_message(_s, {:news}), do: raise("FIX connection will be reset")

  defp react_to_fix_message(state, {:logon}) do
    Logger.debug("FIX logon successful")
    state
  end

  defp react_to_fix_message(state, {:execution_report, execution_report}) do
    # if order is filled/expired, relay to trader
    case execution_report.order_status do
      @order_filled ->
        from = Map.get(state.outstanding_execution_reports, execution_report.client_order_id)
        GenServer.reply(from, {:executed, executionreport_to_tradereport(execution_report)})
        delete_outstanding_order(state, execution_report.client_order_id)

      @order_canceled ->
        raise("Order canceled: #{inspect(execution_report)}")

      @order_rejected ->
        raise("Order rejected: #{inspect(execution_report)}")

      @order_expired ->
        # FOK orders are expired if they can't be filled immediately
        from = Map.get(state.outstanding_execution_reports, execution_report.client_order_id)
        GenServer.reply(from, {:expired, nil})
        delete_outstanding_order(state, execution_report.client_order_id)

      _ ->
        state
    end
  end

  defp react_to_fix_message(state, {:unknown, message}) do
    Logger.error("Unknown message")
    Logger.debug(inspect(message))
    state
  end

  defp delete_outstanding_order(state, client_order_id) do
    %{
      state
      | outstanding_execution_reports:
          Map.delete(
            state.outstanding_execution_reports,
            client_order_id
          )
    }
  end

  @buy_side Const.OrderSide.buy()
  @sell_side Const.OrderSide.sell()

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
      fees: execution_report.fees
    }
  end

  defp generate_client_order_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16() |> String.downcase()
  end
end
