import Config

config :harjus,
  balance_exchange: Balance.Exchange.Mock,
  price_streamer_exchange: PriceStreamer.Exchange.Mock,
  trade_client_exchange: Trader.TradeClient.Exchange.Mock
