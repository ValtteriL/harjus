import Config

if Config.config_env() == :dev do
  DotenvParser.load_file(".env")
end

# Now variables from `.env` are loaded into system env
config :harjus,
  max_trading_path_length: ConfigHelper.get_env("MAX_TRADING_PATH_LENGTH", 2, :int),
  start_symbols: ConfigHelper.get_env("START_SYMBOLS", [], :list),
  commission: ConfigHelper.get_env("COMMISSION", Decimal.from_float(0.001), :decimal),
  binance_ed25519_api_key: ConfigHelper.get_env("BINANCE_ED25519_API_KEY", "", :str),
  binance_ed25519_private_key: ConfigHelper.get_env("BINANCE_ED25519_PRIVATE_KEY", "", :str),
  binance_websocket_stream_uri: ConfigHelper.get_env("BINANCE_WEBSOCKET_STREAM_URI", "", :str),
  binance_rest_api_uri: ConfigHelper.get_env("BINANCE_REST_API_URI", "", :str),
  binance_fix_api_hostname: ConfigHelper.get_env("BINANCE_FIX_API_HOSTNAME", "", :str),
  binance_fix_api_port: ConfigHelper.get_env("BINANCE_FIX_API_PORT", 9000, :int),
  binance_market_data_api_uri: ConfigHelper.get_env("BINANCE_MARKET_DATA_API_URI", "", :str),
  market_data_exchange:
    ConfigHelper.get_env("MARKET_DATA_EXCHANGE", MarketData.Exchange.Mock, :module),
  price_streamer_exchange:
    ConfigHelper.get_env("PRICE_STREAMER_EXCHANGE", PriceStreamer.Exchange.Mock, :module),
  trade_client_exchange:
    ConfigHelper.get_env("TRADE_CLIENT_EXCHANGE", TradeClient.Exchange.Mock, :module),
  balance_exchange: ConfigHelper.get_env("BALANCE_EXCHANGE", Balance.Exchange.Mock, :module),
  console_telemetry: ConfigHelper.get_env("CONSOLE_TELEMETRY", false, :bool),
  console_silence: ConfigHelper.get_env("CONSOLE_SILENCE", false, :bool)

# configure logger verbosity
config :logger, level: ConfigHelper.get_env("VERBOSITY", :debug, :atom)

# configure region for ex_aws
config :ex_aws, region: ConfigHelper.get_env("AWS_REGION", "", :str)
