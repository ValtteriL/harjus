#include "Configuration.h"
#include "dotenv.h"
#include <boost/multiprecision/cpp_dec_float.hpp>
#include <filesystem>
#include <stdexcept> // For std::runtime_error
#include <string>

const std::string BINANCE_REST_API_URI = "BINANCE_REST_API_URI";
const std::string BINANCE_FIX_API_HOSTNAME_ORDERENTRY =
    "BINANCE_FIX_API_HOSTNAME_ORDERENTRY";
const std::string BINANCE_FIX_API_HOSTNAME_MARKETDATA =
    "BINANCE_FIX_API_HOSTNAME_MARKETDATA";
const std::string BINANCE_FIX_API_PORT = "BINANCE_FIX_API_PORT";
const std::string BINANCE_ED25519_SEED = "BINANCE_ED25519_SEED";
const std::string BINANCE_ED25519_API_KEY = "BINANCE_ED25519_API_KEY";
const std::string FIX_FILE_DIR = "FIX_FILE_DIR";

std::vector<std::string> split(const std::string &s, char delimiter) {
  std::vector<std::string> tokens;
  std::stringstream ss(s);
  std::string token;
  while (std::getline(ss, token, delimiter)) {
    tokens.push_back(token);
  }
  return tokens;
}

Configuration::Configuration() {
  // load environment from .env if it exists
  auto filename = std::string(".env");
  if (std::filesystem::is_regular_file(filename)) {
    dotenv::init(filename.c_str());
  }

  // Check for required environment variables
  std::vector<std::string> requiredVars = {
      BINANCE_REST_API_URI, BINANCE_FIX_API_HOSTNAME_ORDERENTRY,
      BINANCE_FIX_API_HOSTNAME_MARKETDATA, BINANCE_ED25519_SEED,
      BINANCE_ED25519_API_KEY};
  std::string missingVars;

  for (const auto &var : requiredVars) {
    if (dotenv::getenv(var.c_str(), "").empty()) {
      if (!missingVars.empty())
        missingVars += ", ";
      missingVars += var;
    }
  }

  if (!missingVars.empty()) {
    throw std::runtime_error("Missing required environment variables: " +
                             missingVars);
  }
}

std::string Configuration::getBinanceRESTApiUri() const {
  return dotenv::getenv(BINANCE_REST_API_URI.c_str());
}

std::string Configuration::getBinanceFIXApiHostnameOrderEntry() const {
  return dotenv::getenv(BINANCE_FIX_API_HOSTNAME_ORDERENTRY.c_str());
}

std::string Configuration::getBinanceFIXApiPortOrderEntry() const {
  return dotenv::getenv("BINANCE_FIX_API_PORT_ORDERENTRY", "9000");
}

std::string Configuration::getBinanceFIXApiHostnameMarketData() const {
  return dotenv::getenv(BINANCE_FIX_API_HOSTNAME_MARKETDATA.c_str());
}

std::string Configuration::getBinanceFIXApiPortMarketData() const {
  return dotenv::getenv("BINANCE_FIX_API_PORT_MARKETDATA", "9000");
}

std::string Configuration::getEd25519Seed() const {
  return dotenv::getenv(BINANCE_ED25519_SEED.c_str());
}

std::string Configuration::getEd25519ApiKey() const {
  return dotenv::getenv(BINANCE_ED25519_API_KEY.c_str());
}

int Configuration::getMaxTradingPathLength() const {
  auto maxPathLength = dotenv::getenv("MAX_TRADING_PATH_LENGTH", "3");
  return std::stoi(maxPathLength);
}

std::vector<std::string> Configuration::getStartSymbols() const {
  std::string symbols = dotenv::getenv("START_SYMBOLS", "");
  return split(symbols, ',');
}

std::vector<std::string> Configuration::getBlacklistedStartSymbols() const {
  std::string symbols = dotenv::getenv("BLACKLISTED_START_SYMBOLS", "");
  return split(symbols, ',');
}

boost::multiprecision::cpp_dec_float_50 Configuration::getCommission() const {
  auto commission = dotenv::getenv("COMMISSION", "0.001");
  return boost::multiprecision::cpp_dec_float_50(commission);
}

int Configuration::getLogLevel() const {
  auto logLevel = dotenv::getenv("LOG_LEVEL", "1");
  return std::stoi(logLevel);
}

std::string Configuration::getFixFileStorePath() const {
  return dotenv::getenv(FIX_FILE_DIR.c_str(), "./fix-file-dir");
}
