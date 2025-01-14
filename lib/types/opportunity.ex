defmodule Types.Opportunity do
  @moduledoc """
  Trade report struct
  """

  @enforce_keys [
    :path,
    :profit,
    :capacity
  ]
  defstruct [
    :path,
    :profit,
    :capacity
  ]

  @type t :: %__MODULE__{
          path: String.t(),
          profit: float(),
          capacity: float()
        }
end
