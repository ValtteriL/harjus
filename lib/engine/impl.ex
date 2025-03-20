defmodule Engine.Impl do
  @moduledoc """
  Implementation of the engine
  """

  def new(trading_paths, commission, relative_asset_values) do
    port =
      Port.open(
        {:spawn, Application.get_env(:harjus, :path_to_port)},
        [:binary]
      )

    parameters = %{
      trading_paths: trading_paths,
      commission: commission,
      relative_asset_values: relative_asset_values
    }

    # send parameters to port
    send(port, {self(), {:command, Jason.encode!(parameters)}})
    send(port, {self(), {:command, "\n"}})

    %{port: port}
  end

  def price_update(state = %{port: port}, update) do
    send(port, {self(), {:command, update}})
    send(port, {self(), {:command, "\n"}})
    state
  end
end
