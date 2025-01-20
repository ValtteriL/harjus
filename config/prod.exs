import Config

config :harjus,
  marketdata_exchange: MarketData.Exchange.Binance,
  balance_exchange: Balance.AccountData.Binance,
  price_streamer_exchange: PriceStreamer.Exchange.Binance
