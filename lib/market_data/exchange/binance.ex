defmodule MarketData.Exchange.Binance do
  @moduledoc "Binance specific api calls on market data"

  @behaviour MarketData.Exchange

  # Get all trading pairs from Binance
  def get_symbols do
    base_url = Application.get_env(:harjus, :binance_market_data_api_uri)
    url = "#{base_url}/api/v3/exchangeInfo"

    {:ok, resp} = Req.get(url)

    resp.body["symbols"]
    |> Enum.map(fn x ->
      Map.take(x, ["symbol", "baseAsset", "quoteAsset"])
      # use atoms as keys
      |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
    end)
  end

  # get symbol prices from Binance
  def get_symbol_prices do
    base_url = Application.get_env(:harjus, :binance_market_data_api_uri)
    url = "#{base_url}/api/v3/ticker/price"

    {:ok, resp} = Req.get(url)

    resp.body
    |> Enum.map(fn x -> {x["symbol"], Decimal.from_float(x["price"])} end)
    |> Enum.into(%{})
  end
end
