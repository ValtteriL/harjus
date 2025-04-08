#include "Exchange.h"
#include "Ed25519.h"
#include <cpr/cpr.h>
#include <boost/json.hpp>

/**
 * * @brief Create a signature for the request
 * * @param privateKey The private key to use for signing
 * * @return The base64 encoded signature
 */
std::string createSignature(std::string privateKeySeed)
{
  // https://github.com/binance/binance-connector-python/blob/cf2bfbc634bf92a4d1153dd5b900a998fa9d499f/binance/api.py#L88
  // https://github.com/binance/binance-spot-api-docs/blob/master/rest-api.md#ed25519-keys

  // get unix time in milliseconds
  auto now = std::chrono::system_clock::now();
  auto timestamp = std::chrono::time_point_cast<std::chrono::milliseconds>(now);

  // url-encode timestamp=<timestamp>
  std::string timestampPart = "timestamp=" + std::to_string(timestamp.time_since_epoch().count());

  // create signature
  std::string signature = Ed25519::sign(privateKeySeed, timestampPart);

  // url-encode signature
  std::string uriSignature(timestampPart + "&signature=" + signature);

  return uriSignature;
}

std::string getBalancesJson(std::string uri, std::string apiKey, std::string privateKeySeed)
{
  // create signature
  std::string signature = createSignature(privateKeySeed);

  cpr::Response r = cpr::Get(cpr::Url{uri + "/api/v3/account?" + signature},
                             cpr::Header{{"Connection", "close"}, {"X-MBX-APIKEY", apiKey}});

  if (r.status_code != 200)
  {
    throw std::runtime_error("Error fetching balances from Binance API: (" + std::to_string(r.status_code) + "), " + r.text);
  }

  return r.text;
}

Balance getBalance(IConfiguration &config)
{
  Balance balance;

  // Fetch balance from exchange API
  std::string jsonResponse = getBalancesJson(config.getBinanceRESTApiUri(), config.getEd25519ApiKey(), config.getEd25519Seed());

  try
  {
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
    for (const auto &item : obj["balances"].as_array())
    {
      const boost::json::object &itemObj = item.as_object();
      std::string asset = itemObj.at("asset").as_string().c_str();
      double free = std::stod(itemObj.at("free").as_string().c_str());

      // Update the balance object (assuming Balance has a method to add assets)
      balance.updateBalance(asset, free);
    }
  }
  catch (const boost::json::system_error &e)
  {
    throw std::runtime_error("Failed to parse JSON response: " + std::string(e.what()));
  }

  return balance;
}