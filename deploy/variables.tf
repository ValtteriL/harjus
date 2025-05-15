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

variable "binance_ed25519_seed" {
  description = "The private key seed of the public key uploaded to Binance"
  type        = string
  sensitive   = true
}

variable "max_trading_path_length" {
  description = "Max number of trades to execute in a single path"
  type        = number
  default     = 3
}

variable "start_symbols" {
  description = "The symbols to start trading with"
  type        = string
  default     = ""
}

variable "blacklisted_start_symbols" {
  description = "The symbols to avoid trading with"
  type        = string
  default     = "BNB"
}

variable "commission" {
  description = "The commission percentage to pay for each trade"
  type        = number
  default     = 0.001
}

variable "binance_rest_api_uri" {
  description = "The URI of the Binance REST API"
  type        = string
}

variable "binance_fix_api_hostname_marketdata" {
  description = "The hostname of the Binance FIX MARKETDATA API"
  type        = string
}

variable "binance_fix_api_port_marketdata" {
  description = "The port of the Binance FIX MARKETDATA API"
  type        = number
}

variable "binance_fix_api_hostname_orderentry" {
  description = "The hostname of the Binance FIX ORDERENTRY API"
  type        = string
}

variable "binance_fix_api_port_orderentry" {
  description = "The port of the Binance FIX ORDERENTRY API"
  type        = number
}

variable "log_level" {
  description = "The minimum level for logging. (0 = trace, 1 = debug, 2 = info, 3 = warning, 4 = error, 5 = fatal)"
  type        = number
}
