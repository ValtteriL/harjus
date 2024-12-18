defmodule Binance do
  # Get all trading pairs from Binance
  @spec get_symbols(is_prod :: bool()) :: [
          %{symbol: charlist(), baseAsset: charlist(), quoteAsset: charlist()}
        ]
  def get_symbols(true) do
    get_symbols_from_url("https://api.binance.com/api/v3/exchangeInfo")
  end

  def get_symbols(false) do
    get_symbols_from_url("https://testnet.binance.vision/api/v3/exchangeInfo")
  end

  @spec get_symbols_from_url(url :: charlist()) :: [
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
end
