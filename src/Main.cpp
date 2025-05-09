#include "Application.h"
#include "Arbmapper.h"
#include "Configuration.h"
#include "Engine.h"
#include "Exchange.h"
#include "Execution.h"
#include "ExecutionReport.h"
#include "PriceUpdate.h"
#include "ReservedTrades.h"
#include "ThreadSafeQueue.h"
#include "Trade.h"
#include "Trader.h"
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

std::atomic<bool> running{true};

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

FIX::SessionSettings getFixSessionSettings(const Configuration config) {
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
)";

  // hide screen logging of FIX messages unless highest verbosity used
  if (config.getLogLevel() > 0) {
    fixConfig += R"(
  # silence logging
  ScreenLogShowOutgoing=N
  ScreenLogShowIncoming=N
)";
  }

  // hide events when not in trace or debug mode
  if (config.getLogLevel() > 1) {
    fixConfig += R"(
  # silence logging
  ScreenLogShowEvents=N
  )";
  }

  fixConfig += R"(    
  # sessions
  [SESSION]
  SenderCompID=HARJUSM1
  SessionQualifier=MARKETDATA
  DataDictionary=/home/valtteri/development/harjus/fix-schema/spot-fix-md.xml
  SocketConnectHost=)" +
               config.getBinanceFIXApiHostnameMarketData() +
               R"(
  SocketConnectPort=)" +
               config.getBinanceFIXApiPortMarketData() +
               R"(
    
  [SESSION]
  SenderCompID=HARJUSM2
  SessionQualifier=MARKETDATA
  DataDictionary=/home/valtteri/development/harjus/fix-schema/spot-fix-md.xml
  SocketConnectHost=)" +
               config.getBinanceFIXApiHostnameMarketData() +
               R"(
  SocketConnectPort=)" +
               config.getBinanceFIXApiPortMarketData() +
               R"(

  [SESSION]
  SenderCompID=HARJUSOE
  SessionQualifier=ORDERENTRY
  DataDictionary=/home/valtteri/development/harjus/fix-schema/spot-fix-md.xml
  SocketConnectHost=)" +
               config.getBinanceFIXApiHostnameOrderEntry() +
               R"(
  SocketConnectPort=)" +
               config.getBinanceFIXApiPortOrderEntry() +
               R"(
  )";

  std::istringstream fixConfigStream{fixConfig};

  return FIX::SessionSettings{fixConfigStream};
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
  auto balance = getBalance(config);

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
  std::binary_semaphore semaphore(0);
  ThreadSafeQueue<Execution> executionQueue(semaphore);
  ThreadSafeQueue<ExecutionReport> reportQueue(semaphore);

  ReservedTrades reservedTrades;

  // Extract the list of symbols for subscription
  std::vector<std::string> symbols = getSymbolsFromMap(symbolMap);

  // Log the number of symbols we'll subscribe to
  BOOST_LOG_TRIVIAL(info) << "There are " << symbols.size()
                          << " available trading symbols";

  // fix settings
  auto settings = getFixSessionSettings(config);

  Application application{config, priceUpdateQueue, reportQueue};
  FIX::FileStoreFactory storeFactory{settings};
  FIX::ScreenLogFactory logFactory{settings};

  auto initiator = std::unique_ptr<FIX::Initiator>(new FIX::SSLSocketInitiator{
      application, storeFactory, settings, logFactory});

  // create a jthread to run the application
  std::jthread j_thread_application([&initiator, &application, symbols]() {
    BOOST_LOG_TRIVIAL(debug) << "Starting QuickFIX initiator";

    initiator->start();

    // Wait for the session to be established
    while (!initiator->isLoggedOn()) {
      std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }

    // Subscribe to market data for all symbols
    if (application.subscribeToSymbols(symbols)) {
      BOOST_LOG_TRIVIAL(debug)
          << "Subscribed to " << symbols.size() << " symbols";
    } else {
      std::cerr << "Failed to subscribe to market data." << std::endl;
      BOOST_LOG_TRIVIAL(error) << "Failed to subscribe to market data.";
    }
  });

  // Create the engine
  Engine engine{symbolMap,        tradingPaths,          *balance,
                reservedTrades,   priceUpdateQueue,      executionQueue,
                relativeValueMap, config.getCommission()};

  // create a jthread to run engine
  std::jthread j_thread_engine(
      [&engine](std::stop_token stoken) { engine.run(stoken); });

  // create a trader
  Trader trader{executionQueue, reportQueue, application, *balance,
                reservedTrades};

  // create a jthread to run trader
  std::jthread j_thread_trader(
      [&trader](std::stop_token stoken) { trader.run(stoken); });

  // Start processing execiutions
  BOOST_LOG_TRIVIAL(info) << "Worker threads started. Press Ctrl+C to exit.";

  // wait for ctrl+c

  // Signal handler to set running to false on SIGINT or SIGTERM
  signal(SIGINT, [](int) { running = false; });
  signal(SIGTERM, [](int) { running = false; });

  while (running) {
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
  }

  // remove signal handler for SIGINT
  signal(SIGINT, SIG_DFL);

  BOOST_LOG_TRIVIAL(info)
      << "Stopping threads... Press Ctrl+C to exit immediately.";
  // Stop the engine
  j_thread_engine.request_stop();
  j_thread_engine.join();

  // Stop the trader
  j_thread_trader.request_stop();
  j_thread_trader.join();

  // Stop the application
  initiator->stop();

  BOOST_LOG_TRIVIAL(info) << "Done. Exiting.";

  return 0;
}
