#pragma once

#include "IConfiguration.h"
#include "Position.h"
#include <string>
#include <utility>
#include <vector>

/**
 * @brief Configuration class that implements IConfiguration interface.
 * This class is responsible for loading and providing configuration values
 * from environment variables or default values.
 */

class Configuration : public IConfiguration
{
public:
    virtual ~Configuration() = default;
    Configuration();

    /**
     * @brief Get the static trading paths from configuration.
     * @return A vector of trading paths, where each path is a vector of pairs (symbol, position).
     */
    [[nodiscard]] auto getStaticTradingPaths() const
        -> std::vector<std::vector<std::pair<std::string, Position>>>;

    /**
     * @brief Get the Binance REST API URI.
     * @return The Binance REST API URI as a string.
     */
    [[nodiscard]] auto getBinanceRESTApiUri() const -> std::string override;

    /**
     * @brief Get the Binance FIX API hostname for Order Entry sessions.
     * @return The Binance FIX API hostname as a string.
     */
    [[nodiscard]] auto
    getBinanceFIXApiHostnameOrderEntry() const -> std::string override;

    /**
     * @brief Get the Binance FIX API port for Order Entry hostname.
     * @return The Binance FIX API port as a string.
     */
    [[nodiscard]] auto
    getBinanceFIXApiPortOrderEntry() const -> std::string override;

    /**
     * @brief Get the Binance FIX API hostname for Market Data sessions.
     * @return The Binance FIX API hostname as a string.
     */
    [[nodiscard]] auto
    getBinanceFIXApiHostnameMarketData() const -> std::string override;

    /**
     * @brief Get the Binance FIX API port for Market Data hostname.
     * @return The Binance FIX API port as a string.
     */
    [[nodiscard]] auto
    getBinanceFIXApiPortMarketData() const -> std::string override;

    /**
     * @brief Get the Ed25519 seed.
     * @return The Ed25519 seed as a string.
     */
    [[nodiscard]] auto getEd25519Seed() const -> std::string override;

    /**
     * @brief Get the Ed25519 API key.
     * @return The Ed25519 API key as a string.
     */
    [[nodiscard]] auto getEd25519ApiKey() const -> std::string override;

    /**
     * @brief Get the maximum trading path length.
     * @return The maximum trading path length as an integer.
     */
    [[nodiscard]] auto getMaxTradingPathLength() const -> int override;

    /**
     * @brief Get the assets (currencies) to trade.
     * @return A vector of assets as strings.
     */
    [[nodiscard]] auto getAssets() const -> std::vector<std::string> override;

    /**
     * @brief Get the commission for trading.
     * @return The commission as a PreciseNumber.
     */
    [[nodiscard]] auto getCommission() const -> PreciseNumber override;

    /**
     * @brief Get the Logging level
     * @return The minimum verbosity level messages to be logged.
     * @details 0 = trace, 1 = debug, 2 = info, 3 = warning, 4 = error, 5 = fatal
     */
    [[nodiscard]] auto getLogLevel() const -> int override;

    /**
     * @brief Get the FIX file directory.
     * @return The FIX file directory as a string.
     */
    [[nodiscard]] auto getFixFileStorePath() const -> std::string override;
};
