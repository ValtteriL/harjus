import Config

config :harjus,
  balance_exchange: Balance.Exchange.Binance,
  price_streamer_exchange: PriceStreamer.Exchange.Binance,
  trade_client_exchange: Trader.TradeClient.Exchange.Binance
