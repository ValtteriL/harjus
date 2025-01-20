import Config

config :harjus,
  marketdata_exchange: MarketData.Exchange.Mock,
  balance_exchange: Balance.Exchange.Mock,
  price_streamer_exchange: PriceStreamer.Exchange.Mock
