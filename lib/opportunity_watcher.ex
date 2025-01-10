defmodule OpportunityWatcher do
  @moduledoc """
  Look for arbitrage opportunities in trading paths.
  """

  @type update() ::
          {symbol :: charlist(), ask_price :: float(), ask_qty :: float(), bid_price :: float(),
           bid_qty :: float()}

  @doc """
  Create new opportunity watcher
  """
  @spec start_link(trading_paths :: [TradingSymbol.t()]) :: {:ok, pid()}
  def start_link(trading_paths) do
    initial_state = OpportunityWatcher.Impl.new(trading_paths)
    GenServer.start_link(OpportunityWatcher.Server, initial_state, name: __MODULE__)
  end

  @doc """
  Update trading symbol price and quantity

  This triggers a recalculation of arbitrage opportunities
  """
  @spec price_update(update :: update()) :: :ok
  def price_update(update) do
    GenServer.cast(__MODULE__, {:price_update, update})
  end
end
