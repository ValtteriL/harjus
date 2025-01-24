defmodule MarketData.Arbmapper do
  @moduledoc """
  Module for finding arbitrage opportunities.
  """

  alias MarketData.Arbmapper.Impl
  alias Types.TradingSymbol

  @doc """
  Generate trading paths and symbols to subscribe to from symbols

  Returns trading symbols to buy that make up a cycle

  Does not return trading paths of depth 1, as they are not useful for arbitrage

  starting_paths can be provided to limit to cycles that start and end at those symbols
  This also limits the symbols to subscribe to to those in the paths
  """
  @spec generate_trading_paths(
          symbols :: [
            %{symbol: charlist(), baseAsset: charlist(), quoteAsset: charlist()}
          ],
          opts :: [
            starting_symbols: [charlist()],
            depth: integer()
          ]
        ) ::
          {trading_paths :: [[TradingSymbol.t()]], symbol_list :: [charlist()]}
  defdelegate generate_trading_paths(symbols, opts \\ []), to: Impl
end
