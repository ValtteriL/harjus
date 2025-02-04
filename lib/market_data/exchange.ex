defmodule MarketData.Exchange do
  @moduledoc """
  Exchange behaviour
  """

  alias MarketData.Types.Symbol

  @callback get_symbols() :: [
              Symbol.t()
            ]
  @callback get_symbol_prices() :: %{String.t() => Decimal.t()}

  def get_symbols, do: impl().get_symbols()
  def get_symbol_prices, do: impl().get_symbol_prices()
  defp impl, do: Application.get_env(:harjus, :market_data_exchange)
end
