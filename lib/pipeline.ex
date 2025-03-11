defmodule Pipeline do
  @moduledoc """
  Pipeline for processing price updates and dispatching traders
  """

  alias Pipeline.Server
  alias Types.TradingSymbol

  require Decimal

  @doc """
  Create new pipeline
  """
  @spec start_link(
          trading_paths :: list(list(TradingSymbol.t())),
          commission :: Decimal.t(),
          relative_asset_values :: map()
        ) :: {:ok, pid()}
  def start_link(trading_paths, commission, relative_asset_values) do
    GenServer.start_link(Server, {trading_paths, commission, relative_asset_values},
      name: __MODULE__
    )
  end

  def child_spec(args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, args}
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
