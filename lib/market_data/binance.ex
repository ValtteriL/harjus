defmodule MarketData.Binance do
  @moduledoc "Binance specific api calls on market data"

  # Get all trading pairs from Binance
  @spec get_symbols(is_prod :: bool()) :: [
          %{symbol: charlist(), baseAsset: charlist(), quoteAsset: charlist()}
        ]
  def get_symbols(true) do
    get_symbols_from_url("https://data-api.binance.vision/api/v3/exchangeInfo")
  end

  def get_symbols(false) do
    get_symbols_from_url("https://testnet.binance.vision/api/v3/exchangeInfo")
  end

  @spec get_symbols_from_url(url :: String.t()) :: [
          %{symbol: charlist(), baseAsset: charlist(), quoteAsset: charlist()}
        ]
  defp get_symbols_from_url(url) do
    {:ok, resp} = Req.get(url)

    resp.body["symbols"]
    |> Enum.map(fn x ->
      Map.take(x, ["symbol", "baseAsset", "quoteAsset"])
      # use atoms as keys
      |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
    end)
  end

  # get symbol prices from Binance
  @spec get_symbol_prices(is_prod :: bool()) :: %{String.t() => float()}
  def get_symbol_prices(true) do
    get_symbol_prices_from_url("https://data-api.binance.vision/api/v3/ticker/price")
  end

  def get_symbol_prices(false) do
    get_symbol_prices_from_url("https://testnet.binance.vision/api/v3/ticker/price")
  end

  defp get_symbol_prices_from_url(url) do
    {:ok, resp} = Req.get(url)

    resp.body
    |> Enum.map(fn x -> {x["symbol"], String.to_float(x["price"])} end)
    |> Enum.into(%{})
  end
end
