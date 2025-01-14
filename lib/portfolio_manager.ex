defmodule PortfolioManager do
  @moduledoc """
  Process for filtering, and prioritizing opportunities.

  Gets opportunities from the OpportunityWatcher,
  filters out unprofitable ones,
  and sends the most profitable to Executor, if any.
  """

  alias Types.Opportunity

  defmodule Args do
    @moduledoc """
    Struct for PortfolioManager arguments
    """
    @enforce_keys [:min_profit_percentage, :min_capacity, :commission, :relative_asset_values]
    defstruct [
      :min_profit_percentage,
      :min_capacity,
      :commission,
      :relative_asset_values
    ]

    @type t :: %__MODULE__{
            min_profit_percentage: float(),
            min_capacity: float(),
            commission: float(),
            relative_asset_values: %{String.t() => float()}
          }
  end

  alias PortfolioManager.Impl

  @doc """
  Start the portfolio manager
  """
  @spec start_link(args :: Args.t()) :: {:ok, pid()}
  def start_link(args) do
    GenStage.start_link(PortfolioManager.Stage, Impl.new(args), name: __MODULE__)
  end

  @doc """
  Send opportunities to Portfolio Manager
  """
  @spec opportunity_update(opportunities :: [Opportunity.t()]) :: :ok
  def opportunity_update(opportunities) do
    GenStage.cast(__MODULE__, {:opportunity_update, opportunities})
  end
end
