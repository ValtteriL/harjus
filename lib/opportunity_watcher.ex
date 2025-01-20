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

  @doc """
  Create new opportunity watcher
  """
  @spec start_link(args :: Args.t()) :: {:ok, pid()}
  def start_link(args) do
    GenStage.start_link(Stage, Impl.new(args), name: __MODULE__)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end
end
