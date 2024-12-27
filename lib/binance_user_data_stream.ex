defmodule BinanceUserDataStream do
  @moduledoc """
  Module for handling user data stream subscription messages and parsing of received events.
  """

  @spec subscribe_message() :: String.t()
  def subscribe_message() do
    Poison.encode!(%{method: "SUBSCRIBE", params: ["!userData"], id: "user_data_sub"})
  end

  @spec parse_message(msg :: String.t()) ::
          {:error, any()}
          | {:sub_ack}
          | {:user_data_event, map()}
          | {:unknown, map()}
  def parse_message(msg) do
    case Poison.decode(msg) do
      {:error, error} ->
        {:error, error}

      {:ok, message} ->
        cond do
          message["id"] == "user_data_sub" and message["result"] == nil ->
            {:sub_ack}

          Map.has_key?(message, "e") ->
            {:user_data_event, message}

          true ->
            {:unknown, message}
        end
    end
  end
end
