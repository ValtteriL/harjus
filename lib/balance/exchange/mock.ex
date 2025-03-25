defmodule Balance.Exchange.Mock do
  @moduledoc "Mock for api calls on account balance"

  @behaviour Balance.Exchange

  def get_balances do
    %{
      "USDT" => Decimal.new("100.0"),
      "BTC" => Decimal.new("1.0"),
      "BNB" => Decimal.new("100000.0")
    }
  end
end
