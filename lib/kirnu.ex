defmodule Kirnu do
  @moduledoc """
  Documentation for `Kirnu`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Kirnu.hello()
      :world

  """
  def hello do
    :world
  end

  def start do
    Websocket.start_link("wss://stream.binance.com:9443/ws/BTCUSD@bookTicker", %{})
  end


  @doc """
  Get all symbols from Binance.

  ## Examples

      iex> Kirnu.get_symbols()
      [%{symbol: "BTCUSD", baseAsset: "BTC", quoteAsset: "USD"}]
  """
  @spec get_symbols() :: [%{symbol: charlist(), baseAsset: charlist(), quoteAsset: charlist()}]
  defp get_symbols do
    {:ok, resp} = Req.get("https://api.binance.com/api/v3/exchangeInfo")

    resp.body["symbols"]
    |> Enum.map(fn x -> Map.take(x, ["symbol", "baseAsset", "quoteAsset"]) end)
  end
end
