defmodule Balance.AccountData.Mock do
  @moduledoc "Mock for api calls on account balance"

  def get_balances do
    %{
      "USDT" => Decimal.new("100.0"),
      "BTC" => Decimal.new("1.0")
    }
  end
end
