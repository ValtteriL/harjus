import Config

config :harjus,
  balance_exchange: Balance.Exchange.Mock,
  trade_client_exchange: Trader.TradeClient.Exchange.Mock
