#include "Exchange.h"
#include "Ed25519.h"
#include "PreciseNumber.h"
#include <boost/json.hpp>
#include <cpr/cpr.h>
#include <stdexcept>

/**
 * * @brief Create a signature for the request
 * * @param privateKey The private key to use for signing
 * * @return The base64 encoded signature
 */
std::string createSignature(std::string privateKeySeed) {
  // https://github.com/binance/binance-connector-python/blob/cf2bfbc634bf92a4d1153dd5b900a998fa9d499f/binance/api.py#L88
  // https://github.com/binance/binance-spot-api-docs/blob/master/rest-api.md#ed25519-keys

  // get unix time in milliseconds
  auto now = std::chrono::system_clock::now();
  auto timestamp = std::chrono::time_point_cast<std::chrono::milliseconds>(now);

  // url-encode timestamp=<timestamp>
  std::string timestampPart =
      "timestamp=" + std::to_string(timestamp.time_since_epoch().count());

  // create signature
  std::string signature = Ed25519::sign(privateKeySeed, timestampPart);

  // url-encode signature
  std::string uriSignature(timestampPart + "&signature=" + signature);

  return uriSignature;
}

std::string getBalancesJson(std::string uri, std::string apiKey,
                            std::string privateKeySeed) {
  // create signature
  std::string signature = createSignature(privateKeySeed);

  cpr::Response r =
      cpr::Get(cpr::Url{uri + "/api/v3/account?" + signature},
               cpr::Header{{"Connection", "close"}, {"X-MBX-APIKEY", apiKey}});

  if (r.status_code == 0) {
    throw std::runtime_error("CPR Error fetching balances: (" +
                             r.error.message + ")");
  } else if (r.status_code != 200) {
    throw std::runtime_error("Error fetching balances: (" +
                             std::to_string(r.status_code) + "), " + r.text);
  }

  return r.text;
}

std::unique_ptr<Balance> getBalance(IConfiguration &config) {
  auto balance = std::make_unique<Balance>();

  // Fetch balance from exchange API
  std::string jsonResponse =
      getBalancesJson(config.getBinanceRESTApiUri(), config.getEd25519ApiKey(),
                      config.getEd25519Seed());

  try {
    // Parse JSON response using Boost.JSON
    boost::json::value json = boost::json::parse(jsonResponse);
    boost::json::object obj = json.as_object();

    // Assuming the JSON contains an array of balances
    // {
    //   "balances": [
    //     { "asset": "BTC", "free": "0.5" },
    //     { "asset": "ETH", "free": "1.0" }
    //   ]
    // }
    for (const auto &item : obj["balances"].as_array()) {
      const boost::json::object &itemObj = item.as_object();
      std::string asset = itemObj.at("asset").as_string().c_str();
      auto free = itemObj.at("free").as_string().c_str();

      // Update the balance object (assuming Balance has a method to add assets)
      balance->updateBalance(asset, PreciseNumber{free});
    }
  } catch (const boost::json::system_error &e) {
    throw std::runtime_error("Failed to parse JSON response: " +
                             std::string(e.what()));
  }

  return balance;
}

std::unordered_map<std::string, Symbol *> getSymbols(IConfiguration &config) {
  std::unordered_map<std::string, Symbol *> symbols;

  // Fetch exchange info from Binance API
  std::string uri = config.getBinanceRESTApiUri() + "/api/v3/exchangeInfo";
  cpr::Response r = cpr::Get(cpr::Url{uri});

  if (r.status_code == 0) {
    throw std::runtime_error("CPR Error fetching exchange info: (" +
                             r.error.message + ")");
  } else if (r.status_code != 200) {
    throw std::runtime_error("Error fetching exchange info: (" +
                             std::to_string(r.status_code) + "), " + r.text);
  }

  // Parse JSON response
  try {
    boost::json::value json = boost::json::parse(r.text);
    boost::json::object obj = json.as_object();

    for (const auto &item : obj["symbols"].as_array()) {
      boost::json::object symbolObj = item.as_object();

      if (!symbolObj["isSpotTradingAllowed"].as_bool()) {
        continue;
      }

      Symbol *symbol = new Symbol();
      symbol->symbol = symbolObj["symbol"].as_string().c_str();
      symbol->baseAsset = symbolObj["baseAsset"].as_string().c_str();
      symbol->quoteAsset = symbolObj["quoteAsset"].as_string().c_str();
      symbol->baseAssetPrecision = symbolObj["baseAssetPrecision"].as_int64();
      symbol->quoteAssetPrecision = symbolObj["quoteAssetPrecision"].as_int64();

      for (const auto &filter : symbolObj["filters"].as_array()) {
        boost::json::object filterObj = filter.as_object();
        std::string filterType = filterObj["filterType"].as_string().c_str();

        if (filterType == "NOTIONAL") {
          symbol->minNotional =
              PreciseNumber{filterObj["minNotional"].as_string().c_str()};
        } else if (filterType == "LOT_SIZE") {
          symbol->baseAssetIncrement =
              PreciseNumber{filterObj["stepSize"].as_string().c_str()};
        } else if (filterType == "PRICE_FILTER") {
          symbol->quoteAssetIncrement =
              PreciseNumber{filterObj["tickSize"].as_string().c_str()};
        }
      }

      symbols[symbol->symbol] = symbol;
    }
  } catch (const boost::json::system_error &e) {
    throw std::runtime_error("Failed to parse JSON response: " +
                             std::string(e.what()));
  }

  return symbols;
}

std::unordered_map<std::string, PreciseNumber>
getRelativeValues(IConfiguration &config,
                  const std::unordered_map<std::string, Symbol *> &symbols) {
  std::unordered_map<std::string, PreciseNumber> relativeValues;

  // Fetch symbol prices from Binance API
  std::string uri = config.getBinanceRESTApiUri() + "/api/v3/ticker/price";
  cpr::Response r = cpr::Get(cpr::Url{uri});

  if (r.status_code == 0) {
    throw std::runtime_error("CPR Error fetching prices: (" + r.error.message +
                             ")");
  } else if (r.status_code != 200) {
    throw std::runtime_error("Error fetching symbol prices: (" +
                             std::to_string(r.status_code) + "), " + r.text);
  }

  // Parse JSON response
  std::unordered_map<std::string, PreciseNumber> symbolPrices;
  try {
    boost::json::value json = boost::json::parse(r.text);
    for (const auto &item : json.as_array()) {
      boost::json::object priceObj = item.as_object();
      std::string symbol = priceObj["symbol"].as_string().c_str();
      PreciseNumber price{priceObj["price"].as_string().c_str()};
      symbolPrices[symbol] = price;
    }
  } catch (const boost::json::system_error &e) {
    throw std::runtime_error("Failed to parse JSON response: " +
                             std::string(e.what()));
  }

  // Calculate relative values in Bitcoin
  PreciseNumber lowestValue = std::numeric_limits<PreciseNumber>::max();
  for (const auto &[symbolName, symbol] : symbols) {
    if (symbol->quoteAsset == "BTC") {
      // price already in BTC (shorting gets btc)
      relativeValues[symbol->baseAsset] = symbolPrices[symbolName];
      lowestValue = PreciseNumber::min(lowestValue, symbolPrices[symbolName]);
    } else if (symbol->baseAsset == "BTC") {
      // price in 1 / BTC (longing gets btc)
      PreciseNumber value = PreciseNumber{"1"} / symbolPrices[symbolName];
      relativeValues[symbol->quoteAsset] = value;
      lowestValue = PreciseNumber::min(lowestValue, value);
    }
  }

  // Assign lowest value to currencies not tradable to Bitcoin
  for (const auto &[symbolName, symbol] : symbols) {
    if (relativeValues.find(symbol->baseAsset) == relativeValues.end()) {
      relativeValues[symbol->baseAsset] = lowestValue;
    }
    if (relativeValues.find(symbol->quoteAsset) == relativeValues.end()) {
      relativeValues[symbol->quoteAsset] = lowestValue;
    }
  }

  // Set Bitcoin's value to 1
  relativeValues["BTC"] = PreciseNumber{"1"};

  return relativeValues;
}