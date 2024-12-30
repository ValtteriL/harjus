defmodule BinanceWSSpotApi do
  @moduledoc "Module for parsing and constructing requests for the WS Spot API"

  @type trading_symbol() :: {charlist(), :long | :short}

  # https://github.com/binance/binance-spot-api-docs/blob/master/web-socket-api.md#place-new-order-trade
  @spec market_order_request(
          trading_symbol :: trading_symbol(),
          quantity :: float(),
          api_key :: String.t(),
          api_secret :: String.t()
        ) :: String.t()
  def market_order_request({symbol, direction}, quantity, api_key, api_secret) do
    side =
      case direction do
        :long -> "BUY"
        :short -> "SELL"
      end

    params = %{
      symbol: symbol,
      side: side,
      type: "MARKET",
      quantity: quantity,
      apiKey: api_key,
      timestamp: System.os_time(:millisecond)
    }

    signature = calculate_signature(params, api_secret)

    params_with_signature = Map.put(params, :signature, signature)

    Poison.encode!(%{method: "order.place", params: params_with_signature, id: "market_order_id"})
  end

  @spec calculate_signature(params :: map(), api_secret :: String.t()) :: String.t()
  def calculate_signature(params, api_secret) do
    # sort params by key in alphabetical order, format as parameter=value pairs separated by &
    payload =
      params
      |> Map.to_list()
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map_join("&", fn {key, value} -> "#{key}=#{value}" end)

    # hash the payload with the api secret & encode result as HEX
    :crypto.mac(:hmac, :sha256, api_secret, payload) |> Base.encode16(case: :lower)
  end

  @spec parse_message(msg :: String.t()) ::
          {:error, any()}
          | {:order_ack}
          | {:unknown, map()}
  def parse_message(msg) do
    case Poison.decode(msg) do
      {:error, error} ->
        {:error, error}

      {:ok, message} ->
        if message["id"] == "market_order_id" do
          {:order_ack}
        else
          {:unknown, message}
        end
    end
  end
end
