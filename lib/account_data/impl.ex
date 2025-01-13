defmodule AccountData.Impl do
  @moduledoc """
  Implementation of the account data
  """

  alias AccountData.Binance

  def get_balances do
    Binance.get_balances(
      Application.fetch_env!(:harjus, :binance_ed25519_api_key),
      Application.fetch_env!(:harjus, :binance_ed25519_private_key)
    )
  end
end
