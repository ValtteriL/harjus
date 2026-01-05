#include "Configuration.h"
#include "PreciseNumber.h"
#include "dotenv.h"
#include <filesystem>
#include <stdexcept> // For std::runtime_error
#include <string>

const std::string BINANCE_REST_API_URI = "BINANCE_REST_API_URI";
const std::string BINANCE_FIX_API_HOSTNAME_ORDERENTRY =
    "BINANCE_FIX_API_HOSTNAME_ORDERENTRY";
const std::string BINANCE_FIX_API_HOSTNAME_MARKETDATA =
    "BINANCE_FIX_API_HOSTNAME_MARKETDATA";
const std::string BINANCE_ED25519_SEED = "BINANCE_ED25519_SEED";
const std::string BINANCE_ED25519_API_KEY = "BINANCE_ED25519_API_KEY";
const std::string FIX_FILE_DIR = "FIX_FILE_DIR";
const std::string ASSETS = "ASSETS";
const std::string STATIC_TRADINGPATHS = "STATIC_TRADINGPATHS";

std::vector<std::string> split(const std::string &s, char delimiter)
{
    std::vector<std::string> tokens{};
    std::stringstream ss{s};
    std::string token{};
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

    // Check for required environment variables
    std::vector<std::string> requiredVars = {BINANCE_REST_API_URI,
                                             BINANCE_FIX_API_HOSTNAME_ORDERENTRY,
                                             BINANCE_FIX_API_HOSTNAME_MARKETDATA,
                                             BINANCE_ED25519_SEED,
                                             BINANCE_ED25519_API_KEY,
                                             ASSETS};
    std::string missingVars;

    for (const auto &var : requiredVars)
    {
        if (dotenv::getenv(var.c_str(), "").empty())
        {
            if (!missingVars.empty())
                missingVars += ", ";
            missingVars += var;
        }
    }

    if (!missingVars.empty())
    {
        throw std::runtime_error("Missing required environment variables: " +
                                 missingVars);
    }
}

auto Configuration::getBinanceRESTApiUri() const -> std::string
{
    return dotenv::getenv(BINANCE_REST_API_URI.c_str());
}

auto Configuration::getBinanceFIXApiHostnameOrderEntry() const -> std::string
{
    return dotenv::getenv(BINANCE_FIX_API_HOSTNAME_ORDERENTRY.c_str());
}

auto Configuration::getBinanceFIXApiPortOrderEntry() const -> std::string
{
    return dotenv::getenv("BINANCE_FIX_API_PORT_ORDERENTRY", "9000");
}

auto Configuration::getBinanceFIXApiHostnameMarketData() const -> std::string
{
    return dotenv::getenv(BINANCE_FIX_API_HOSTNAME_MARKETDATA.c_str());
}

auto Configuration::getBinanceFIXApiPortMarketData() const -> std::string
{
    return dotenv::getenv("BINANCE_FIX_API_PORT_MARKETDATA", "9000");
}

auto Configuration::getEd25519Seed() const -> std::string
{
    return dotenv::getenv(BINANCE_ED25519_SEED.c_str());
}

auto Configuration::getEd25519ApiKey() const -> std::string
{
    return dotenv::getenv(BINANCE_ED25519_API_KEY.c_str());
}

auto Configuration::getMaxTradingPathLength() const -> int
{
    auto maxPathLength = dotenv::getenv("MAX_TRADING_PATH_LENGTH", "3");
    return std::stoi(maxPathLength);
}

std::vector<std::string> Configuration::getAssets() const
{
    std::string assets = dotenv::getenv(ASSETS.c_str());
    return split(assets, ',');
}

auto Configuration::getCommission() const -> PreciseNumber
{
    auto commission = dotenv::getenv("COMMISSION", "0.001");
    return PreciseNumber{commission.c_str()};
}

auto Configuration::getLogLevel() const -> int
{
    auto logLevel = dotenv::getenv("LOG_LEVEL", "1");
    return std::stoi(logLevel);
}

auto Configuration::getFixFileStorePath() const -> std::string
{
    return dotenv::getenv(FIX_FILE_DIR.c_str(), "./fix-file-dir");
}

auto Configuration::getStaticTradingPaths() const
    -> std::vector<std::vector<std::pair<std::string, Position>>>
{
    auto staticPathsEnv = dotenv::getenv(STATIC_TRADINGPATHS.c_str());
    if (staticPathsEnv.empty())
    {
        return {};
    }

    std::vector<std::vector<std::pair<std::string, Position>>> paths;
    auto pathStrings = split(staticPathsEnv, ';');

    for (const auto &pathString : pathStrings)
    {
        std::vector<std::pair<std::string, Position>> path;
        auto tradeStrings = split(pathString, ',');

        for (const auto &tradeString : tradeStrings)
        {
            auto parts = split(tradeString, ':');
            if (parts.size() != 2)
            {
                throw std::runtime_error("Invalid static trading path format: " +
                                         tradeString);
            }

            auto symbol = parts[0];
            auto positionStr = parts[1];
            Position position;

            if (positionStr == "LONG")
            {
                position = Position::LONG;
            }
            else if (positionStr == "SHORT")
            {
                position = Position::SHORT;
            }
            else
            {
                throw std::runtime_error("Invalid position in static trading path: " +
                                         positionStr);
            }

            path.emplace_back(symbol, position);
        }
        paths.push_back(path);
    }

    return paths;
}
