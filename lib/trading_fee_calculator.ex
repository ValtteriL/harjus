defmodule TradingFeeCalculator do
  @moduledoc """
  Functions for calculating trading fees
  """

  @type trading_path() :: [TradingSymbol.t()]

  @spec total_commission_percentage(
          trading_path :: trading_path(),
          commission :: float()
        ) :: float()
  @doc """
  Estimate total commission percentage for a trading path

  In reality the total commission is a bit higher, as the traded sum should increase along the path

  source: https://developers.binance.com/docs/binance-spot-api-docs/faqs/commission_faq

  The trading fees announced on binance assumed to include tax and other fees, hence the simple implementation here
  """
  def total_commission_percentage(
        trading_path,
        commission
      ) do
    length(trading_path) * commission
  end
end
