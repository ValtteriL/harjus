import Config

if Config.config_env() == :dev do
  DotenvParser.load_file(".env")
end

# Now variables from `.env` are loaded into system env
config :harjus,
  number_of_traders: ConfigHelper.get_env("NUMBER_OF_TRADERS", 1, :int),
  max_trading_path_length: ConfigHelper.get_env("MAX_TRADING_PATH_LENGTH", 2, :int),
  start_symbols: ConfigHelper.get_env("START_SYMBOLS", [], :list),
  min_profit_percentage: ConfigHelper.get_env("MIN_PROFIT_PERCENTAGE", 0.001, :float),
  min_capacity: ConfigHelper.get_env("MIN_CAPACITY", 0.0, :float),
  commission: ConfigHelper.get_env("COMMISSION", 0.001, :float),
  binance_ed25519_api_key: ConfigHelper.get_env("BINANCE_ED25519_API_KEY", "", :str),
  binance_ed25519_private_key: ConfigHelper.get_env("BINANCE_ED25519_PRIVATE_KEY", "", :str),
  binance_websocket_stream_uri: ConfigHelper.get_env("BINANCE_WEBSOCKET_STREAM_URI", "", :str),
  binance_rest_api_uri: ConfigHelper.get_env("BINANCE_REST_API_URI", "", :str),
  binance_fix_api_hostname: ConfigHelper.get_env("BINANCE_FIX_API_HOSTNAME", "", :str),
  binance_fix_api_port: ConfigHelper.get_env("BINANCE_FIX_API_PORT", 9000, :int),
  binance_market_data_api_uri: ConfigHelper.get_env("BINANCE_MARKET_DATA_API_URI", "", :str)

# configure logger verbosity
config :logger, level: ConfigHelper.get_env("VERBOSITY", :debug, :atom)
