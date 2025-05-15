variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "ap-northeast-1"
}

variable "image_tag" {
  description = "The tag of the Docker image to deploy"
  type        = string
}

variable "binance_ed25519_api_key" {
  description = "The Binance API key (gotten when ED25519 pubkey uploaded to Binance)"
  type        = string
  sensitive   = true
}

variable "binance_ed25519_private_key" {
  description = "The private part of ED25519 key uploaded to Binance"
  type        = string
  sensitive   = true
}

variable "max_trading_path_length" {
  description = "Max number of trades to execute in a single path"
  type        = number
  default     = 2
}

variable "start_symbols" {
  description = "The symbols to start trading with"
  type        = string
  default     = ""
}

variable "blacklisted_start_symbols" {
  description = "The symbols to avoid trading with"
  type        = string
  default     = ""
}

variable "commission" {
  description = "The commission percentage to pay for each trade"
  type        = number
  default     = 0.001
}

variable "binance_websocket_stream_uri" {
  description = "The URI of the Binance WebSocket stream"
  type        = string
}

variable "binance_rest_api_uri" {
  description = "The URI of the Binance REST API"
  type        = string
}

variable "binance_fix_api_hostname" {
  description = "The hostname of the Binance FIX API"
  type        = string
}

variable "binance_fix_api_port" {
  description = "The port of the Binance FIX API"
  type        = number
}

variable "binance_market_data_api_uri" {
  description = "The URI of the Binance Market Data API"
  type        = string
}

variable "verbosity" {
  description = "The verbosity of the logs"
  type        = string
}

variable "market_data_exchange" {
  description = "The exchange module to use in MarketData"
  type        = string
}

variable "price_streamer_exchange" {
  description = "The exchange module to use in PriceStreamer"
  type        = string
}

variable "trade_client_exchange" {
  description = "The exchange module to use in TradeClient"
  type        = string
}

variable "balance_exchange" {
  description = "The exchange module to use in Balance"
  type        = string
}

variable "path_to_port" {
  description = "The path to the harjus port binary"
  type        = string
}
