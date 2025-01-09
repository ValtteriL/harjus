defmodule Binance do
  @moduledoc "Binance specific api calls"
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

  # Get account balances from Binance
  @spec get_balances(is_prod :: bool(), api_key :: String.t(), private_key :: String.t()) :: %{
          String.t() => float()
        }
  def get_balances(true, api_key, private_key) do
    get_balances_from_url("https://api.binance.com/api/v3/account", api_key, private_key)
  end

  def get_balances(false, api_key, private_key) do
    get_balances_from_url("https://testnet.binance.vision/api/v3/account", api_key, private_key)
  end

  # get symbol prices from Binance
  @spec get_symbol_prices() :: %{String.t() => float()}
  def get_symbol_prices do
    {:ok, resp} = Req.get("https://data-api.binance.vision/api/v3/ticker/price")

    resp.body
    |> Enum.map(fn x -> {x["symbol"], String.to_float(x["price"])} end)
    |> Enum.into(%{})
  end

  @spec get_balances_from_url(url :: String.t(), api_key :: String.t(), private_key :: String.t()) ::
          %{String.t() => float()}
  defp get_balances_from_url(url, api_key, private_key) do
    signature = sign_request(private_key)

    {:ok, resp} =
      Req.get("#{url}?#{signature}", headers: ["X-MBX-APIKEY": api_key])

    resp.body["balances"]
    |> Enum.map(fn x -> {x["asset"], String.to_float(x["free"])} end)
    |> Enum.into(%{})
  end

  defp sign_request(private_key) do
    sign_request(%{}, private_key)
  end

  defp sign_request(payload, private_key) do
    # https://github.com/binance/binance-connector-python/blob/cf2bfbc634bf92a4d1153dd5b900a998fa9d499f/binance/api.py#L88
    # https://github.com/binance/binance-spot-api-docs/blob/master/rest-api.md#ed25519-keys

    # timestamp = unix timestamp in milliseconds
    timestamp = System.os_time(:millisecond)
    params = Map.put(payload, :timestamp, timestamp)
    payload = URI.encode_query(params)
    signature = ed25519_sign(private_key, payload)

    URI.encode_query(Map.put(params, :signature, signature))
  end

  @doc """
  Sign a payload with the ed25519 private key
  """
  @spec ed25519_sign(private_key :: String.t(), payload :: String.t()) :: String.t()
  def ed25519_sign(private_key, payload) do
    decoded_key =
      Enum.join(["-----BEGIN PRIVATE KEY-----\n", private_key, "\n-----END PRIVATE KEY-----\n"])
      |> :public_key.pem_decode()
      |> hd()
      |> :public_key.pem_entry_decode()

    signature = :public_key.sign(payload, :sha256, decoded_key)
    Base.encode64(signature)
  end
end
