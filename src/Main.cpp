#include "Application.h"
#include "Arbmapper.h"
#include "Configuration.h"
#include "Exchange.h"
#include "FixConfig.h"
#include "PriceUpdate.h"
#include "Trade.h"
#include "Worker.h"
#include <boost/lockfree/spsc_queue.hpp>
#include <boost/log/core.hpp>
#include <boost/log/expressions.hpp>
#include <boost/log/trivial.hpp>
#include <chrono>
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
std::atomic<bool> isShuttingDown{false};

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

void initLogging(int logLevel) {
  boost::log::core::get()->set_filter(boost::log::trivial::severity >=
                                      logLevel);
}

auto getUniqueSymbolsForTradingPaths(
    const std::vector<std::vector<Trade>> &tradingPaths)
    -> std::vector<std::string> {
  std::unordered_set<std::string> uniqueSymbols{};
  for (const auto &path : tradingPaths) {
    for (const auto &trade : path) {
      uniqueSymbols.insert(trade.symbol()->symbol);
    }
  }
  return {uniqueSymbols.begin(), uniqueSymbols.end()};
}

auto main() -> int {
  banner();
  Configuration config;

  // config logging
  initLogging(config.getLogLevel());

  BOOST_LOG_TRIVIAL(info) << "Starting Harjus";

  // get balance, available symbols & relative values
  BOOST_LOG_TRIVIAL(debug) << "Getting balance";
  auto balance = getBalance(config);

  BOOST_LOG_TRIVIAL(debug) << "Getting symbols";
  auto symbolMap = getSymbols(config);

  BOOST_LOG_TRIVIAL(debug) << "Calculating relative values";
  auto relativeValueMap = getRelativeValues(config, symbolMap);

  // calculate trading paths
  BOOST_LOG_TRIVIAL(debug) << "Calculating trading paths";
  auto tradingPaths = getTradingPaths(symbolMap, config);

  // Define a named constant for the queue size
  constexpr std::size_t QUEUE_SIZE = 1000;

  // Create queues for price updates & executions
  boost::lockfree::spsc_queue<PriceUpdate> priceUpdateQueue{QUEUE_SIZE};
  boost::lockfree::spsc_queue<ExecutionReport> reportQueue{QUEUE_SIZE};

  // Extract the list of symbols for subscription
  auto symbols = getUniqueSymbolsForTradingPaths(tradingPaths);

  // Log info of interest
  BOOST_LOG_TRIVIAL(info) << "There are " << symbolMap.size()
                          << " available trading symbols";

  BOOST_LOG_TRIVIAL(info) << "Focusing only on " << config.getAssets().size()
                          << " assets";

  BOOST_LOG_TRIVIAL(info) << "These form " << tradingPaths.size()
                          << " trading paths";

  BOOST_LOG_TRIVIAL(info) << "These consist of in total " << symbols.size()
                          << " trading symbols";

  // fix settings
  auto fixConfig = FixConfig(config);
  auto settings = fixConfig.sessionSettings();

  Application application{config, priceUpdateQueue, reportQueue, symbolMap};
  FIX::FileStoreFactory storeFactory{settings};
  FIX::ScreenLogFactory logFactory{settings};

  auto initiator =
      FIX::SSLSocketInitiator{application, storeFactory, settings, logFactory};

  // create a jthread to run the application
  std::jthread j_thread_application([&initiator, &application, symbols]() {
    BOOST_LOG_TRIVIAL(debug) << "Starting QuickFIX initiator";

    initiator.start();

    // Wait for the session to be established
    constexpr int SESSION_ESTABLISH_WAIT_MS = 100;
    while (!initiator.isLoggedOn()) {
      std::this_thread::sleep_for(
          std::chrono::milliseconds(SESSION_ESTABLISH_WAIT_MS));
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

  // Create the worker

  Worker worker{tradingPaths,          priceUpdateQueue, reportQueue,
                application,           relativeValueMap, *balance,
                config.getCommission()};

  // create a jthread to run worker
  std::jthread j_thread_worker(
      [&worker](const std::stop_token &stoken) { worker.run(stoken); });

  // Start processing execiutions
  BOOST_LOG_TRIVIAL(info) << "Worker thread started. Press Ctrl+C to exit.";

  // wait for ctrl+c

  // Signal handler to set running to false on SIGINT or SIGTERM
  signal(SIGINT, [](int) { running = false; });
  signal(SIGTERM, [](int) { running = false; });

  constexpr int MAIN_LOOP_SLEEP_MS = 100;
  while (running) {
    std::this_thread::sleep_for(std::chrono::milliseconds(MAIN_LOOP_SLEEP_MS));
  }

  // remove signal handler for SIGINT
  signal(SIGINT, SIG_DFL);

  BOOST_LOG_TRIVIAL(info)
      << "Stopping threads... Press Ctrl+C to exit immediately.";
  // Stop the engine
  j_thread_worker.request_stop();
  j_thread_worker.join();

  // Stop the application
  isShuttingDown = true;
  initiator.stop();

  BOOST_LOG_TRIVIAL(info) << "Done. Exiting.";

  return 0;
}
