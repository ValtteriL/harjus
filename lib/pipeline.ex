defmodule Pipeline do
  @moduledoc """
  Pipeline for processing price updates and dispatching traders
  """

  alias Pipeline.Server

  @doc """
  Create new pipeline
  """
  @spec start_link(args :: tuple()) :: {:ok, pid()}
  def start_link(args = {_trading_paths, _commission, _relative_asset_values}) do
    GenServer.start_link(Server, args, name: __MODULE__)
  end

  def child_spec(args = {_trading_paths, _commission, _relative_asset_values}) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [args]}
    }
  end

  @doc """
  Send price update to pipeline
  """
  @spec price_update(
          symbol :: String.t(),
          ask_price :: Decimal.t(),
          ask_qty :: Decimal.t(),
          bid_price :: Decimal.t(),
          bid_qty :: Decimal.t()
        ) :: :ok
  def price_update(symbol, ask_price, ask_qty, bid_price, bid_qty) do
    GenServer.cast(__MODULE__, {:price_update, {symbol, ask_price, ask_qty, bid_price, bid_qty}})
  end
end
