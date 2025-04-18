#include <iostream>
#include <string>
#include <vector>
#include <chrono>
#include <thread>
#include "Configuration.h"
#include "Exchange.h"
#include "Trade.h"
#include "Arbmapper.h"
#include "Application.h"
#include "PriceUpdate.h"
#include <boost/lockfree/queue.hpp>
#include <quickfix/SSLSocketInitiator.h>
#include <quickfix/ThreadedSSLSocketInitiator.h>
#include <quickfix/SocketInitiator.h>
#include <quickfix/SessionSettings.h>
#include <quickfix/FileStore.h>
#include <quickfix/Log.h>

void banner()
{
  std::cout << R"(
                      :=======:.
                    :============.
                  .-==+++=++======-
              .:==========++*+++==+=.
           :==-=--=---===+=====++=:
        :=**=::--=====Harjus======+=:.
      :++++=:-:=-=-==-==============+++=:
     ==+=::-:-=-=========+=====+===++===+*=:
    :=++=:::==:-=====-::::::-========+*+++++=.
    :++--:-:-:::::::..    .=+==+=::--==++++++=.
     ..                     :.  .    :=*+-+++***=:
                                       :+:.=**+*=:
                                           :***.
                                            =++:
                                            .*+:
                                             =+:
                                             :=

    )" << std::endl;
}

// Extract symbols from symbol map
std::vector<std::string> getSymbolsFromMap(const std::unordered_map<std::string, Symbol> &symbolMap)
{
  std::vector<std::string> symbols;
  symbols.reserve(symbolMap.size());

  for (const auto &[symbol, _] : symbolMap)
  {
    symbols.push_back(symbol);
  }

  return symbols;
}

// Process the price update queue
void processPriceQueue(boost::lockfree::queue<PriceUpdate *> &queue)
{
  size_t updateCount = 0;

  while (true)
  {
    PriceUpdate *update = nullptr;
    if (queue.pop(update))
    {
      if (update)
      {
        updateCount++;
        std::cout << "Update #" << updateCount << " - symbol:" << update->symbol << std::endl;
        delete update; // Clean up the heap allocated update
      }
    }

    // Small sleep to avoid spinning the CPU
    std::this_thread::sleep_for(std::chrono::milliseconds(1));
  }
}

int main()
{
  banner();
  Configuration config;

  // get balance, available symbols & relative values
  Balance balance = getBalance(config);
  std::unordered_map<std::string, Symbol> symbolMap = getSymbols(config);
  std::unordered_map<std::string, boost::multiprecision::cpp_dec_float_50> relativeValueMap = getRelativeValues(config, symbolMap);

  // calculate trading paths
  std::vector<std::string> skipSymbols = config.getBlacklistedStartSymbols();
  int maxDepth = config.getMaxTradingPathLength();
  std::vector<std::vector<Trade>> tradingPaths = getTradingPaths(&symbolMap, maxDepth, skipSymbols);

  // Create lockfree queue for price updates
  boost::lockfree::queue<PriceUpdate *> priceUpdateQueue(1000); // Queue size of 1000 updates

  // Extract the list of symbols for subscription
  std::vector<std::string> symbols = getSymbolsFromMap(symbolMap);

  // Log the number of symbols we'll subscribe to
  std::cout << "Subscribing to " << symbols.size() << " trading symbols" << std::endl;

  // FIX Engine config
  std::string fixConfig = R"(
  # default settings for sessions
  [DEFAULT]
  ConnectionType=initiator
  SenderCompID=HARJUS
  TargetCompID=SPOT
  DefaultApplVerID=FIX.4.4
  BeginString=FIX.4.4
  SocketConnectPort=)" +
                          config.getBinanceFIXApiPort() +
                          R"(
  SocketConnectHost=)" +
                          config.getBinanceFIXApiHostname() +
                          R"(
    
  # set TCP_NODELAY (disable Nagle's algorithm)
  # this is required for low latency
  SocketNodelay=Y
    
  # market data session
  [SESSION]
  SessionQualifier=MARKETDATA
  SocketConnectHost=fix-md.binance.com
  DataDictionary=/home/valtteri/development/harjus/fix-schema/spot-fix-md.xml
    
  )";

  // stream to the string
  std::istringstream fixConfigStream{fixConfig};

  try
  {
    FIX::SessionSettings settings{fixConfigStream};

    Application application{config, priceUpdateQueue};
    FIX::FileStoreFactory storeFactory{settings};
    FIX::ScreenLogFactory logFactory{settings};

    auto initiator = std::unique_ptr<FIX::Initiator>(new FIX::SSLSocketInitiator{application, storeFactory, settings, logFactory});

    initiator->start();
    std::cout << "FIX initiator started successfully." << std::endl;

    // Subscribe to market data for all symbols
    if (application.subscribeToSymbols(symbols))
    {
      std::cout << "Successfully subscribed to " << symbols.size() << " symbols." << std::endl;
    }
    else
    {
      std::cerr << "Failed to subscribe to market data." << std::endl;
    }

    // Start processing price updates in the main thread
    std::cout << "Starting to process price updates. Press Ctrl+C to exit." << std::endl;
    processPriceQueue(priceUpdateQueue);

    // This is unreachable with the current implementation since processPriceQueue runs indefinitely
    initiator->stop();

    return 0;
  }
  catch (std::exception &e)
  {
    std::cout << "Error: " << e.what() << std::endl;
    return 1;
  }

  return 0;
}
