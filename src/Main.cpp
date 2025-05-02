#include "Application.h"
#include "Arbmapper.h"
#include "Configuration.h"
#include "Engine.h"
#include "Exchange.h"
#include "Execution.h"
#include "PriceUpdate.h"
#include "ReservedTrades.h"
#include "Trade.h"
#include <boost/lockfree/queue.hpp>
#include <boost/log/core.hpp>
#include <boost/log/expressions.hpp>
#include <boost/log/trivial.hpp>
#include <chrono>
#include <filesystem>
#include <iostream>
#include <quickfix/FileStore.h>
#include <quickfix/Log.h>
#include <quickfix/SSLSocketInitiator.h>
#include <quickfix/SessionSettings.h>
#include <quickfix/SocketInitiator.h>
#include <quickfix/ThreadedSSLSocketInitiator.h>
#include <string>
#include <thread>
#include <vector>

void banner() {
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
std::vector<std::string>
getSymbolsFromMap(const std::unordered_map<std::string, Symbol *> &symbolMap) {
  std::vector<std::string> symbols;
  symbols.reserve(symbolMap.size());

  for (const auto &[symbol, _] : symbolMap) {
    symbols.push_back(symbol);
  }

  return symbols;
}

// Process the price update queue
void processExecutionQueue(boost::lockfree::queue<Execution *> &queue) {
  size_t execCount = 0;

  while (true) {
    Execution *ex = nullptr;
    if (queue.pop(ex)) {
      if (ex) {
        execCount++;
        std::cout << "Execution #" << execCount
                  << " - total profit:" << ex->getTotalProfit() << std::endl;
        delete ex; // Clean up the heap allocated update
      }
    }

    // Small sleep to avoid spinning the CPU
    // TODO: avoid
    std::this_thread::sleep_for(std::chrono::microseconds(100));
  }
}

void initLogging(int logLevel) {
  boost::log::core::get()->set_filter(boost::log::trivial::severity >=
                                      logLevel);
}

void prepareFixFileStore(const std::string &dir) {
  std::filesystem::create_directory(dir);

  for (const auto &entry : std::filesystem::directory_iterator(dir)) {
    if (entry.path().extension() == ".session" ||
        entry.path().extension() == ".body" ||
        entry.path().extension() == ".header" ||
        entry.path().extension() == ".seqnums") {
      std::filesystem::remove(entry.path());
    }
  }
}

int main() {
  banner();
  Configuration config;

  // config logging
  initLogging(config.getLogLevel());

  BOOST_LOG_TRIVIAL(info) << "Starting Harjus";

  // Create directory if it doesn't exist and delete .session files
  std::string fixFileStorePath = config.getFixFileStorePath();
  prepareFixFileStore(fixFileStorePath);

  // get balance, available symbols & relative values
  BOOST_LOG_TRIVIAL(debug) << "Getting balance";
  Balance balance = getBalance(config);

  BOOST_LOG_TRIVIAL(debug) << "Getting symbols";
  std::unordered_map<std::string, Symbol *> symbolMap = getSymbols(config);

  BOOST_LOG_TRIVIAL(debug) << "Calculating relative values";
  std::unordered_map<std::string, boost::multiprecision::cpp_dec_float_50>
      relativeValueMap = getRelativeValues(config, symbolMap);

  // calculate trading paths
  BOOST_LOG_TRIVIAL(debug) << "Calculating trading paths";
  std::vector<std::string> skipSymbols = config.getBlacklistedStartSymbols();
  int maxDepth = config.getMaxTradingPathLength();
  std::vector<std::vector<Trade> *> tradingPaths =
      getTradingPaths(&symbolMap, maxDepth, skipSymbols);

  // Create lockfree queues for price updates & executions
  boost::lockfree::queue<PriceUpdate *> priceUpdateQueue(1000);
  boost::lockfree::queue<Execution *> executionQueue(1000);

  ReservedTrades reservedTrades;

  // Extract the list of symbols for subscription
  std::vector<std::string> symbols = getSymbolsFromMap(symbolMap);
  // std::vector<std::string> symbols = {"ETHBTC", "LTCBTC", "BNBBTC",
  // "TRXBTC"};

  // Log the number of symbols we'll subscribe to
  BOOST_LOG_TRIVIAL(info) << "Subscribing to " << symbols.size()
                          << " trading symbols";

  // FIX Engine config
  std::string fixConfig = R"(
  # default settings for sessions
  [DEFAULT]
  StartTime=00:00:00
  EndTime=00:00:00
  HeartBtInt=30
  FileStorePath=)" + config.getFixFileStorePath() +
                          R"(
  ConnectionType=initiator
  TargetCompID=SPOT
  DefaultApplVerID=FIX.4.4
  BeginString=FIX.4.4
    
  # set TCP_NODELAY (disable Nagle's algorithm)
  # this is required for low latency
  SocketNodelay=Y
    
  # sessions
  [SESSION]
  SenderCompID=HARJUSM1
  SessionQualifier=MARKETDATA
  DataDictionary=/home/valtteri/development/harjus/fix-schema/spot-fix-md.xml
  SocketConnectHost=)" + config.getBinanceFIXApiHostnameMarketData() +
                          R"(
  SocketConnectPort=)" + config.getBinanceFIXApiPortMarketData() +
                          R"(
    
  [SESSION]
  SenderCompID=HARJUSM2
  SessionQualifier=MARKETDATA
  DataDictionary=/home/valtteri/development/harjus/fix-schema/spot-fix-md.xml
  SocketConnectHost=)" + config.getBinanceFIXApiHostnameMarketData() +
                          R"(
  SocketConnectPort=)" + config.getBinanceFIXApiPortMarketData() +
                          R"(
  )";

  // stream to the string
  std::istringstream fixConfigStream{fixConfig};

  FIX::SessionSettings settings{fixConfigStream};

  Application application{config, priceUpdateQueue};
  FIX::FileStoreFactory storeFactory{settings};
  FIX::ScreenLogFactory logFactory{settings};

  auto initiator = std::unique_ptr<FIX::Initiator>(new FIX::SSLSocketInitiator{
      application, storeFactory, settings, logFactory});

  initiator->start();
  BOOST_LOG_TRIVIAL(debug) << "FIX initiator started successfully.";

  // Wait for the session to be established
  while (!initiator->isLoggedOn()) {
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
  }

  // Subscribe to market data for all symbols
  if (application.subscribeToSymbols(symbols)) {
    BOOST_LOG_TRIVIAL(debug) << "Subscribed to symbols: " << symbols.size();
  } else {
    std::cerr << "Failed to subscribe to market data." << std::endl;
    BOOST_LOG_TRIVIAL(error) << "Failed to subscribe to market data.";
  }

  // Create the engine
  Engine engine{symbolMap,        tradingPaths,          balance,
                reservedTrades,   priceUpdateQueue,      executionQueue,
                relativeValueMap, config.getCommission()};

  // create a jthread to run engine
  std::jthread j_thread([&engine]() { engine.run(); });

  // Start processing execiutions
  BOOST_LOG_TRIVIAL(info)
      << "Starting to process executions. Press Ctrl+C to exit.";
  processExecutionQueue(executionQueue);

  // This is unreachable with the current implementation since
  // processExecutionQueue runs indefinitely
  initiator->stop();

  return 0;
}
