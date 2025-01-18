defmodule OpportunityWatcher do
  @moduledoc """
  Look for arbitrage opportunities in trading paths.
  """

  alias OpportunityWatcher.Impl
  alias OpportunityWatcher.Stage
  alias Types.TradingSymbol

  defmodule Args do
    @moduledoc """
    Struct for OpportunityWatcher arguments
    """
    @enforce_keys [:min_profit_percentage, :min_capacity, :commission, :trading_paths]
    defstruct [
      :min_profit_percentage,
      :min_capacity,
      :commission,
      :trading_paths
    ]

    @type t :: %__MODULE__{
            min_profit_percentage: Decimal.t(),
            min_capacity: Decimal.t(),
            commission: Decimal.t(),
            trading_paths: [TradingSymbol.t()]
          }
  end

  @type update() ::
          {symbol :: charlist(), ask_price :: Decimal.t(), ask_qty :: Decimal.t(),
           bid_price :: Decimal.t(), bid_qty :: Decimal.t()}

  @doc """
  Create new opportunity watcher
  """
  @spec start_link(args :: Args.t()) :: {:ok, pid()}
  def start_link(args) do
    GenStage.start_link(Stage, Impl.new(args), name: __MODULE__)
  end

  @doc """
  Update trading symbol price and quantity

  This triggers a recalculation of arbitrage opportunities
  """
  @spec price_update(update :: update()) :: :ok
  def price_update(update) do
    GenStage.cast(__MODULE__, {:price_update, update})
  end
end
