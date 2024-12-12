import Config

if Config.config_env() == :dev do
  DotenvParser.load_file(".env")
end

# Now variables from `.env` are loaded into system env
config :kirnu,
  max_trading_path_length: ConfigHelper.get_env("MAX_TRADING_PATH_LENGTH", 4, :int),
  start_symbols: ConfigHelper.get_env("START_SYMBOLS", [], :list),
  min_profit_percentage: ConfigHelper.get_env("MIN_PROFIT_PERCENTAGE", 0.001, :float),
  min_capacity: ConfigHelper.get_env("MIN_CAPACITY", 0.0, :float)
