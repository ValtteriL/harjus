defmodule PortfolioManager do
  @moduledoc """
  Process for filtering, and prioritizing opportunities.

  Gets opportunities from the OpportunityWatcher,
  filters out unprofitable ones,
  and sends the most profitable to Trader, if any.
  """

  defmodule Args do
    @moduledoc """
    Struct for PortfolioManager arguments
    """
    @enforce_keys [:relative_asset_values]
    defstruct [
      :relative_asset_values
    ]

    @type t :: %__MODULE__{
            relative_asset_values: %{String.t() => Decimal.t()}
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

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end
end
