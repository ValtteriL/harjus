#pragma once

#include "PreciseNumber.h"
#include <string>

class IConfiguration
{
public:
    virtual ~IConfiguration() = default;
    [[nodiscard]] virtual auto getBinanceRESTApiUri() const -> std::string = 0;
    [[nodiscard]] virtual auto
    getBinanceFIXApiHostnameOrderEntry() const -> std::string = 0;
    [[nodiscard]] virtual auto
    getBinanceFIXApiHostnameMarketData() const -> std::string = 0;
    [[nodiscard]] virtual auto
    getBinanceFIXApiPortOrderEntry() const -> std::string = 0;
    [[nodiscard]] virtual auto
    getBinanceFIXApiPortMarketData() const -> std::string = 0;
    [[nodiscard]] virtual auto
    getEd25519Seed() const -> std::string = 0; // private key seed in base64
    [[nodiscard]] virtual auto getEd25519ApiKey() const
        -> std::string = 0; // public key in PEM without header and trailer
    [[nodiscard]] virtual auto getMaxTradingPathLength() const -> int = 0;
    [[nodiscard]] virtual auto getAssets() const -> std::vector<std::string> = 0;
    [[nodiscard]] virtual auto getCommission() const -> PreciseNumber = 0;
    [[nodiscard]] virtual auto getLogLevel() const -> int = 0;
    [[nodiscard]] virtual auto getFixFileStorePath() const -> std::string = 0;
    [[nodiscard]] virtual auto getSSLKeyLogFile() const -> std::string = 0;
};
