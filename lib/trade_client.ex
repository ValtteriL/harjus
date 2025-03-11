defmodule TradeClient do
  @moduledoc """
  Client for placing trades
  """
  alias TradeClient.Impl

  @doc """
  Start trade client process
  """
  @spec start_link(args :: any()) :: {:ok, pid}
  def start_link(_args) do
    Task.start_link(fn ->
      # trap exits to allow for finishing trades on exit
      Process.flag(:trap_exit, true)
      {:ok, _} = Impl.new()

      # sleep forever
      receive do
        _ -> :ok
      end
    end)
  end

  @doc """
  Place a limit order
  """
  @spec limit_order(
          trading_symbol :: Types.TradingSymbol.t(),
          quantity :: Decimal.t(),
          price :: Decimal.t()
        ) :: {:executed, Types.TradeReport.t()} | {:expired, any()}
  defdelegate limit_order(trading_symbol, quantity, price), to: Impl
end
