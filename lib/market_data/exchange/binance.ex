defmodule MarketData.Exchange.Binance do
  @moduledoc "Binance specific api calls on market data"

  @behaviour MarketData.Exchange

  alias MarketData.Types.Symbol

  # Get all trading pairs from Binance
  def get_symbols do
    base_url = Application.get_env(:harjus, :binance_market_data_api_uri)
    url = "#{base_url}/api/v3/exchangeInfo"

    {:ok, resp} = Req.get(url)

    resp.body["symbols"]
    |> Enum.map(fn x ->
      Map.take(x, [
        "symbol",
        "baseAsset",
        "quoteAsset",
        "baseAssetPrecision",
        "quoteAssetPrecision",
        "filters"
      ])
      # use atoms as keys
      |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
      # get asset increments
      |> Map.put(:baseAssetIncrement, get_base_asset_increment(x["filters"]))
      |> Map.put(:quoteAssetIncrement, get_quote_asset_increment(x["filters"]))
      # delete filters
      |> Map.delete(:filters)
    end)
    |> Enum.map(fn x ->
      %Symbol{
        symbol: x[:symbol],
        baseAsset: x[:baseAsset],
        quoteAsset: x[:quoteAsset],
        baseAssetPrecision: x[:baseAssetPrecision],
        quoteAssetPrecision: x[:quoteAssetPrecision],
        baseAssetIncrement: x[:baseAssetIncrement],
        quoteAssetIncrement: x[:quoteAssetIncrement]
      }
    end)
  end

  defp get_base_asset_increment(filters) do
    get_asset_increment(filters, "LOT_SIZE", "stepSize")
  end

  defp get_quote_asset_increment(filters) do
    get_asset_increment(filters, "PRICE_FILTER", "tickSize")
  end

  defp get_asset_increment(filters, filter_type, key) do
    filters
    |> Enum.find(fn filter -> filter["filterType"] == filter_type end)
    |> Map.get(key)
    |> Decimal.new()
  end

  # get symbol prices from Binance
  def get_symbol_prices do
    base_url = Application.get_env(:harjus, :binance_market_data_api_uri)
    url = "#{base_url}/api/v3/ticker/price"

    {:ok, resp} = Req.get(url)

    resp.body
    |> Enum.map(fn x -> {x["symbol"], Decimal.from_float(String.to_float(x["price"]))} end)
    |> Enum.into(%{})
  end
end
