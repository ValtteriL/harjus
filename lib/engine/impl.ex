defmodule Engine.Impl do
  @moduledoc """
  Implementation of the engine
  """

  def new(_trading_paths, _commission, _relative_asset_values) do
    # TODO: commission from env?

    port =
      Port.open(
        {:spawn,
         "/home/valtteri/development/harjus/harjus-port/build/Desktop_Qt_6_8_2-Debug/harjus-port"},
        [:binary]
      )

    send(port, {self(), {:command, "hello"}})
    # flush()
    :ok
  end

  def price_update(_state, _update) do
    :ok
  end
end
