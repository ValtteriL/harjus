#include "dotenv.h"
#include "Configuration.h"
#include <string>
#include <boost/multiprecision/cpp_dec_float.hpp>
#include <filesystem>

std::vector<std::string> split(const std::string &s, char delimiter)
{
  std::vector<std::string> tokens;
  std::stringstream ss(s);
  std::string token;
  while (std::getline(ss, token, delimiter))
  {
    tokens.push_back(token);
  }
  return tokens;
}

Configuration::Configuration()
{
  // load environment from .env if it exists
  auto filename = std::string(".env");
  if (std::filesystem::is_regular_file(filename))
  {
    dotenv::init(filename.c_str());
  }
}

std::string Configuration::getBinanceRESTApiUri() const
{
  return dotenv::getenv("BINANCE_REST_API_URI");
}

std::string Configuration::getBinanceFIXApiHostname() const
{
  return dotenv::getenv("BINANCE_FIX_API_HOSTNAME");
}

std::string Configuration::getBinanceFIXApiPort() const
{
  return dotenv::getenv("BINANCE_FIX_API_PORT", "9000");
}
std::string Configuration::getEd25519Seed() const
{
  return dotenv::getenv("BINANCE_ED25519_SEED", "");
}

std::string Configuration::getEd25519ApiKey() const
{
  return dotenv::getenv("BINANCE_ED25519_API_KEY", "");
}

int Configuration::getMaxTradingPathLength() const
{
  auto maxPathLength = dotenv::getenv("MAX_TRADING_PATH_LENGTH", "3");
  return std::stoi(maxPathLength);
}

std::vector<std::string> Configuration::getStartSymbols() const
{
  std::string symbols = dotenv::getenv("START_SYMBOLS", "");
  return split(symbols, ',');
}

std::vector<std::string> Configuration::getBlacklistedStartSymbols() const
{
  std::string symbols = dotenv::getenv("BLACKLISTED_START_SYMBOLS", "");
  return split(symbols, ',');
}

boost::multiprecision::cpp_dec_float_50 Configuration::getCommission() const
{
  auto commission = dotenv::getenv("COMMISSION", "0.001");
  return boost::multiprecision::cpp_dec_float_50(commission);
}
