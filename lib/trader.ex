defmodule Trader do
  @moduledoc """
  Process for executing trades.

  Traders get approved and prioritized opportunities from PortfolioManager,
  and execute them.
  """

  alias Trader.Consumer

  @doc """
  Start the trader supervisor

  ## Parameters
    * `max_number_workers` - The maximum number of workers to start
  """
  @spec start_link(max_number_workers :: integer()) :: {:ok, pid()}
  def start_link(max_number_workers),
    do: ConsumerSupervisor.start_link(Consumer, max_number_workers, name: __MODULE__)

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end
end
