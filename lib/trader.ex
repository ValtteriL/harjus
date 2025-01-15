defmodule Trader do
  @moduledoc """
  Process for executing trades.

  Gets approved and prioritized opportunities from PortfolioManager,
  and executes them.
  """

  alias Trader.Impl
  alias Trader.Stage

  @doc """
  Start the trader
  """
  @spec start_link(arg :: any()) :: {:ok, pid()}
  def start_link(arg), do: GenStage.start_link(Stage, Impl.new(arg), name: __MODULE__)
end
