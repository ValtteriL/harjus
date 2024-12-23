defmodule TradingFeeCalculator do
  @moduledoc """
  Functions for calculating trading fees
  """

  @type trading_symbol() :: {charlist(), :long | :short}
  @type trading_path() :: [trading_symbol()]

  @spec total_commission_percentage(
          trading_path :: trading_path(),
          standard_commission_taker :: float(),
          standard_commission_buyer :: float(),
          standard_commission_seller :: float(),
          tax_commission_taker :: float(),
          tax_commission_buyer :: float(),
          tax_commission_seller :: float(),
          discount :: float()
        ) :: float()
  @doc """
  Estimate total commission percentage for a trading path

  In reality the total commission is a bit higher, as the traded sum should increase along the path

  source: https://developers.binance.com/docs/binance-spot-api-docs/faqs/commission_faq
  """
  def total_commission_percentage(
        trading_path,
        standard_commission_taker,
        standard_commission_buyer,
        standard_commission_seller,
        tax_commission_taker,
        tax_commission_buyer,
        tax_commission_seller,
        discount
      ) do
    trading_path
    |> Enum.reduce(0, fn trading_symbol, acc ->
      standard_commission(
        trading_symbol,
        standard_commission_taker,
        standard_commission_buyer,
        standard_commission_seller
      ) * (1.0 - discount) +
        tax_commission(
          trading_symbol,
          tax_commission_taker,
          tax_commission_buyer,
          tax_commission_seller
        ) +
        acc
    end)
  end

  @spec standard_commission(
          trading_symbol :: trading_symbol(),
          standard_commission_taker :: float(),
          standard_commission_buyer :: float(),
          standard_commission_seller :: float()
        ) :: float()
  defp standard_commission(
         trading_symbol,
         standard_commission_taker,
         standard_commission_buyer,
         standard_commission_seller
       ) do
    standard_commission_taker +
      case trading_symbol do
        {_, :long} -> standard_commission_buyer
        {_, :short} -> standard_commission_seller
      end
  end

  @spec tax_commission(
          trading_symbol :: trading_symbol(),
          tax_commission_taker :: float(),
          tax_commission_buyer :: float(),
          tax_commission_seller :: float()
        ) :: float()
  defp tax_commission(
         trading_symbol,
         tax_commission_taker,
         tax_commission_buyer,
         tax_commission_seller
       ) do
    tax_commission_taker +
      case trading_symbol do
        {_, :long} -> tax_commission_buyer
        {_, :short} -> tax_commission_seller
      end
  end
end
