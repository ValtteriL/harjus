#pragma once

#include "IConfiguration.h"
#include <string>

/**
 * @brief Configuration class that implements IConfiguration interface.
 * This class is responsible for loading and providing configuration values
 * from environment variables or default values.
 */

class Configuration : public IConfiguration
{
public:
  Configuration();

  /**
   * @brief Get the Binance REST API URI.
   * @return The Binance REST API URI as a string.
   */
  std::string getBinanceRESTApiUri() const override;

  /**
   * @brief Get the Binance FIX API hostname.
   * @return The Binance FIX API hostname as a string.
   */
  std::string getBinanceFIXApiHostname() const override;

  /**
   * @brief Get the Binance FIX API port.
   * @return The Binance FIX API port as a string.
   */
  std::string getBinanceFIXApiPort() const override;

  /**
   * @brief Get the Ed25519 seed.
   * @return The Ed25519 seed as a string.
   */
  std::string getEd25519Seed() const override;

  /**
   * @brief Get the Ed25519 API key.
   * @return The Ed25519 API key as a string.
   */
  std::string getEd25519ApiKey() const override;

  /**
   * @brief Get the maximum trading path length.
   * @return The maximum trading path length as an integer.
   */
  int getMaxTradingPathLength() const override;

  /**
   * @brief Get the start symbols for trading.
   * @return A vector of start symbols as strings.
   */
  std::vector<std::string> getStartSymbols() const override;

  /**
   * @brief Get the blacklisted start symbols for trading.
   * @return A vector of blacklisted start symbols as strings.
   */
  std::vector<std::string> getBlacklistedStartSymbols() const override;

  /**
   * @brief Get the commission for trading.
   * @return The commission as a boost::multiprecision::cpp_dec_float_50.
   */
  boost::multiprecision::cpp_dec_float_50 getCommission() const override;
};
