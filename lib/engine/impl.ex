defmodule Engine.Impl do
  @moduledoc """
  Implementation of the engine
  """

  def new(_trading_paths, _commission, _relative_asset_values) do
    # get commission from env instead?
    port =
      Port.open(
        {:spawn, Application.get_env(:harjus, :path_to_port)},
        [:binary]
      )

    %{port: port}
  end

  def price_update(state = %{port: port}, update) do
    send(port, {self(), {:command, update}})
    send(port, {self(), {:command, "\n"}})
    state
  end
end
