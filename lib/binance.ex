defmodule Binance do
  # Get all trading pairs from Binance
  @spec get_symbols() :: [%{symbol: charlist(), baseAsset: charlist(), quoteAsset: charlist()}]
  def get_symbols do
    {:ok, resp} = Req.get("https://api.binance.com/api/v3/exchangeInfo")

    resp.body["symbols"]
    |> Enum.map(fn x -> Map.take(x, ["symbol", "baseAsset", "quoteAsset"]) end)
  end
end
