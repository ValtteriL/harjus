#pragma once

#include "IConfiguration.h"
#include <string>

/**
 * @brief Configuration class that implements IConfiguration interface.
 * This class is responsible for loading and providing configuration values
 * from environment variables or default values.
 */

class Configuration : public IConfiguration {
public:
  Configuration();

  /**
   * @brief Get the Binance REST API URI.
   * @return The Binance REST API URI as a string.
   */
  std::string getBinanceRESTApiUri() const override;

  /**
   * @brief Get the Binance FIX API hostname for Order Entry sessions.
   * @return The Binance FIX API hostname as a string.
   */
  std::string getBinanceFIXApiHostnameOrderEntry() const override;

  /**
   * @brief Get the Binance FIX API port for Order Entry hostname.
   * @return The Binance FIX API port as a string.
   */
  std::string getBinanceFIXApiPortOrderEntry() const override;

  /**
   * @brief Get the Binance FIX API hostname for Market Data sessions.
   * @return The Binance FIX API hostname as a string.
   */
  std::string getBinanceFIXApiHostnameMarketData() const override;

  /**
   * @brief Get the Binance FIX API port for Market Data hostname.
   * @return The Binance FIX API port as a string.
   */
  std::string getBinanceFIXApiPortMarketData() const override;

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
   * @brief Get the blacklisted start assets for trading.
   * @return A vector of blacklisted start assets as strings.
   */
  std::vector<std::string> getBlacklistedStartAssets() const override;

  /**
   * @brief Get the blacklisted symbols for trading.
   * @return A vector of blacklisted symbols as strings.
   */
  std::vector<std::string> getBlacklistedSymbols() const override;

  /**
   * @brief Get the commission for trading.
   * @return The commission as a PreciseNumber.
   */
  PreciseNumber getCommission() const override;

  /**
   * @brief Get the Logging level
   * @return The minimum verbosity level messages to be logged.
   * @details 0 = trace, 1 = debug, 2 = info, 3 = warning, 4 = error, 5 = fatal
   */
  int getLogLevel() const override;

  /**
   * @brief Get the FIX file directory.
   * @return The FIX file directory as a string.
   */
  std::string getFixFileStorePath() const override;
};
