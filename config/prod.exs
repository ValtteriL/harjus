import Config

config :harjus,
  marketdata_exchange: MarketData.Exchange.Binance,
  balance_exchange: Balance.Exchange.Binance,
  price_streamer_exchange: PriceStreamer.Exchange.Binance,
  trade_client_exchange: Trader.TradeClient.Exchange.Binance
