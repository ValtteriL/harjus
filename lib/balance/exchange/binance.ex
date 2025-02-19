defmodule Balance.Exchange.Binance do
  @moduledoc "Binance specific api calls"

  @behaviour Balance.Exchange

  @spec get_balances() :: %{String.t() => Decimal.t()}
  def get_balances do
    get_balances(
      Application.fetch_env!(:harjus, :binance_ed25519_api_key),
      Application.fetch_env!(:harjus, :binance_ed25519_private_key)
    )
  end

  # Get account balances from Binance
  defp get_balances(api_key, private_key) do
    uri = Application.fetch_env!(:harjus, :binance_rest_api_uri)
    signature = sign_request(private_key)

    resp = Req.get!("#{uri}/api/v3/account?#{signature}", headers: ["X-MBX-APIKEY": api_key])

    # verify status code is 200, otherwise raise an error
    case resp.status do
      200 -> :ok
      _ -> raise "Failed to get balances from Binance: #{inspect(resp)}"
    end

    resp.body["balances"]
    |> Enum.map(fn x -> {x["asset"], Decimal.from_float(String.to_float(x["free"]))} end)
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

  @spec ed25519_sign(private_key :: String.t(), payload :: String.t()) :: String.t()
  defp ed25519_sign(private_key, payload) do
    decoded_key =
      Enum.join(["-----BEGIN PRIVATE KEY-----\n", private_key, "\n-----END PRIVATE KEY-----\n"])
      |> :public_key.pem_decode()
      |> hd()
      |> :public_key.pem_entry_decode()

    signature = :public_key.sign(payload, :sha256, decoded_key)
    Base.encode64(signature)
  end
end
